import 'package:flutter/material.dart';

import '../models/operation.dart';
import '../models/wallet.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../widgets/transaction_item.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.reloadToken,
  });

  final int reloadToken;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
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
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
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
        ApiService.getOperations(),
        ApiService.getWallets(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _operations = results[0] as List<OperationModel>;
        _wallets = results[1] as List<WalletModel>;
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
        _error = 'Could not load transactions.';
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final monthlyExpense = _operations
        .where((operation) => operation.isExpense)
        .fold<double>(0, (sum, operation) => sum + operation.amount);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total expenses',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${monthlyExpense.toStringAsFixed(2)} RUB',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_operations.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('Операций пока нет.'),
            )
          else
            ..._operations.map(
              (operation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TransactionItem(
                  title: operation.title,
                  subtitle:
                      '${_walletLabel(operation.walletId)} • ${_formatDate(operation.createdAt)}',
                  amount:
                      '${operation.isExpense ? '-' : '+'}${operation.amount.toStringAsFixed(2)} ${operation.currency}',
                  icon:
                      operation.isExpense ? Icons.north_east : Icons.south_west,
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
