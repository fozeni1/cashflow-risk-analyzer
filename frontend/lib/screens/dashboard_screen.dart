import 'package:flutter/material.dart';

import '../models/operation.dart';
import '../models/wallet.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chart_widget.dart';
import '../widgets/transaction_item.dart';
import 'add_expense_screen.dart';
import 'create_wallet_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onLoggedOut,
  });

  final VoidCallback onLoggedOut;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  int _reloadToken = 0;

  Future<void> _openCreateWallet() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
    );

    if (created == true && mounted) {
      setState(() {
        _reloadToken++;
      });
    }
  }

  Future<void> _openAddTransaction() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );

    if (created == true && mounted) {
      setState(() {
        _reloadToken++;
      });
    }
  }

  void _refreshCurrentTab() {
    setState(() {
      _reloadToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Transactions', 'Account'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EA),
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: _currentIndex == 2
            ? null
            : [
                IconButton(
                  onPressed: _refreshCurrentTab,
                  icon: const Icon(Icons.refresh),
                ),
              ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardHomeTab(
            reloadToken: _reloadToken,
            onCreateWallet: _openCreateWallet,
            onAddTransaction: _openAddTransaction,
          ),
          TransactionsScreen(reloadToken: _reloadToken),
          ProfileScreen(
            reloadToken: _reloadToken,
            onCreateWallet: _openCreateWallet,
            onLoggedOut: widget.onLoggedOut,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) {
            _refreshCurrentTab();
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({
    super.key,
    required this.reloadToken,
    required this.onCreateWallet,
    required this.onAddTransaction,
  });

  final int reloadToken;
  final Future<void> Function() onCreateWallet;
  final Future<void> Function() onAddTransaction;

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  double _balance = 0;
  double? _predictedExpense;
  List<OperationModel> _operations = const [];
  List<WalletModel> _wallets = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        ApiService.getBalance(),
        ApiService.getPrediction(),
        ApiService.getOperations(),
        ApiService.getWallets(),
      ]);

      if (!mounted) {
        return;
      }

      final predictionMap = results[1] as Map<String, double>?;
      setState(() {
        _balance = results[0] as double;
        _predictedExpense = predictionMap?['predicted_expense'];
        _operations = results[2] as List<OperationModel>;
        _wallets = results[3] as List<WalletModel>;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not load dashboard data.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _DashboardErrorState(
        message: _error!,
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _HeroCard(
            balance: _balance,
            predictedExpense: _predictedExpense,
          ),
          const SizedBox(height: 18),
          if (_wallets.isEmpty)
            _EmptyWalletCard(
              onCreateWallet: widget.onCreateWallet,
            )
          else
            _WalletStrip(wallets: _wallets),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Weekly expenses',
            child: SizedBox(
              height: 132,
              child: ChartWidget(operations: _operations),
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Recent operations',
            actionLabel: _operations.isEmpty ? null : 'Add new',
            onAction: _operations.isEmpty ? null : widget.onAddTransaction,
          ),
          const SizedBox(height: 10),
          if (_operations.isEmpty)
            _SectionCard(
              title: 'No operations yet',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Когда появятся доходы и расходы, они будут отображаться здесь.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _wallets.isEmpty
                        ? widget.onCreateWallet
                        : widget.onAddTransaction,
                    child: Text(
                        _wallets.isEmpty ? 'Create wallet' : 'Add operation'),
                  ),
                ],
              ),
            )
          else
            ..._operations.take(5).map(
                  (operation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TransactionItem(
                      title: operation.title,
                      subtitle:
                          '${_walletLabel(operation.walletId)} • ${_formatDate(operation.createdAt)}',
                      amount:
                          '${operation.isExpense ? '-' : '+'}${operation.amount.toStringAsFixed(2)} ${operation.currency}',
                      icon: operation.isExpense
                          ? Icons.north_east
                          : Icons.south_west,
                      amountColor: operation.isExpense
                          ? const Color(0xFFB42318)
                          : const Color(0xFF117A65),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _walletLabel(int walletId) {
    for (final wallet in _wallets) {
      if (wallet.id == walletId) {
        return wallet.name;
      }
    }
    return 'Wallet #$walletId';
  }

  String _formatDate(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.balance,
    required this.predictedExpense,
  });

  final double balance;
  final double? predictedExpense;

  @override
  Widget build(BuildContext context) {
    final expense = predictedExpense;
    final balanceAfter = expense == null ? null : balance - expense;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF10403B), Color(0xFF1D6F5D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available liquidity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '${balance.toStringAsFixed(2)} RUB',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(
                label: 'AI expense forecast',
                value: expense == null
                    ? 'Unavailable'
                    : '${expense.toStringAsFixed(2)} RUB',
              ),
              _MetricChip(
                label: 'Projected balance',
                value: balanceAfter == null
                    ? 'Unavailable'
                    : '${balanceAfter.toStringAsFixed(2)} RUB',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _WalletStrip extends StatelessWidget {
  const _WalletStrip({
    required this.wallets,
  });

  final List<WalletModel> wallets;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final wallet = wallets[index];
          return Container(
            width: 220,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${wallet.balance.toStringAsFixed(2)} ${wallet.currency}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyWalletCard extends StatelessWidget {
  const _EmptyWalletCard({
    required this.onCreateWallet,
  });

  final Future<void> Function() onCreateWallet;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'No wallets yet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сначала создайте кошелек. После этого можно будет добавлять доходы и расходы.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreateWallet,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Create wallet'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
