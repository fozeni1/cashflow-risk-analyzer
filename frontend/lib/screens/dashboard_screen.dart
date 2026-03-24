import 'package:flutter/material.dart';

import '../models/dashboard_data.dart';
import '../models/operation.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.login,
    required this.baseUrl,
    required this.onLogout,
  });

  final String login;
  final String baseUrl;
  final VoidCallback onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ApiService _api;

  final TextEditingController _walletNameController = TextEditingController();
  final TextEditingController _walletBalanceController = TextEditingController(
    text: '0',
  );
  final TextEditingController _operationAmountController =
      TextEditingController();
  final TextEditingController _operationDescriptionController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSavingWallet = false;
  bool _isSavingOperation = false;
  String? _error;

  double _totalBalance = 0;
  List<Wallet> _wallets = <Wallet>[];
  List<Operation> _operations = <Operation>[];

  String _selectedCurrency = 'rub';
  String _selectedOperationType = 'income';
  String? _selectedWalletName;

  @override
  void initState() {
    super.initState();
    _api = ApiService(baseUrl: widget.baseUrl);
    _loadData();
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _walletBalanceController.dispose();
    _operationAmountController.dispose();
    _operationDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.fetchDashboard(widget.login);
      if (!mounted) {
        return;
      }

      setState(() {
        _applyData(data);
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
        _error = 'Failed to load dashboard.';
        _isLoading = false;
      });
    }
  }

  void _applyData(DashboardData data) {
    _totalBalance = data.totalBalance;
    _wallets = data.wallets;
    _operations = data.operations;

    final walletNames = _wallets.map((wallet) => wallet.name).toSet();
    if (_selectedWalletName == null || !walletNames.contains(_selectedWalletName)) {
      _selectedWalletName = _wallets.isEmpty ? null : _wallets.first.name;
    }
  }

  Future<void> _createWallet() async {
    final name = _walletNameController.text.trim();
    final initialBalance = _walletBalanceController.text.trim();

    if (name.isEmpty || initialBalance.isEmpty) {
      _showMessage('Enter wallet name and start balance.');
      return;
    }

    setState(() {
      _isSavingWallet = true;
    });

    try {
      await _api.createWallet(
        login: widget.login,
        name: name,
        currency: _selectedCurrency,
        initialBalance: initialBalance,
      );

      _walletNameController.clear();
      _walletBalanceController.text = '0';
      await _loadData();
      _showMessage('Wallet created.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Failed to create wallet.');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingWallet = false;
        });
      }
    }
  }

  Future<void> _createOperation() async {
    final walletName = _selectedWalletName;
    final amount = _operationAmountController.text.trim();
    final description = _operationDescriptionController.text.trim();

    if (walletName == null) {
      _showMessage('Create a wallet first.');
      return;
    }

    if (amount.isEmpty) {
      _showMessage('Enter amount.');
      return;
    }

    setState(() {
      _isSavingOperation = true;
    });

    try {
      await _api.createOperation(
        login: widget.login,
        walletName: walletName,
        type: _selectedOperationType,
        amount: amount,
        description: description,
      );

      _operationAmountController.clear();
      _operationDescriptionController.clear();
      await _loadData();
      _showMessage('Operation added.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Failed to add operation.');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingOperation = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashflow: ${widget.login}'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryCard(totalBalance: _totalBalance),
                      const SizedBox(height: 16),
                      _buildWalletSection(),
                      const SizedBox(height: 16),
                      _buildOperationSection(),
                      const SizedBox(height: 16),
                      _buildOperationsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWalletSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wallets', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_wallets.isEmpty)
              const Text('No wallets yet.')
            else
              ..._wallets.map(
                (wallet) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(wallet.name),
                  subtitle: Text(wallet.currency.toUpperCase()),
                  trailing: Text(_formatMoney(wallet.balance)),
                ),
              ),
            const Divider(height: 32),
            TextField(
              controller: _walletNameController,
              decoration: const InputDecoration(
                labelText: 'Wallet name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _walletBalanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Initial balance',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedCurrency),
              initialValue: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
              ),
              items: const ['rub', 'usd', 'eur']
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedCurrency = value;
                });
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSavingWallet ? null : _createWallet,
              child: _isSavingWallet
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create wallet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New operation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedWalletName ?? 'wallet-empty'),
              initialValue: _selectedWalletName,
              decoration: const InputDecoration(
                labelText: 'Wallet',
                border: OutlineInputBorder(),
              ),
              items: _wallets
                  .map(
                    (wallet) => DropdownMenuItem(
                      value: wallet.name,
                      child: Text(wallet.name),
                    ),
                  )
                  .toList(),
              onChanged: _wallets.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _selectedWalletName = value;
                      });
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedOperationType),
              initialValue: _selectedOperationType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedOperationType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _operationAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _operationDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSavingOperation ? null : _createOperation,
              child: _isSavingOperation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save operation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operations', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_operations.isEmpty)
              const Text('No operations yet.')
            else
              ..._operations.map(
                (operation) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: operation.isIncome
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      operation.isIncome ? Icons.south_west : Icons.north_east,
                      color: operation.isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(_formatMoney(operation.amount)),
                  subtitle: Text(
                    [
                      operation.currency.toUpperCase(),
                      if (operation.category != null &&
                          operation.category!.trim().isNotEmpty)
                        operation.category!,
                    ].join(' • '),
                  ),
                  trailing: Text(
                    operation.type.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double value) => value.toStringAsFixed(2);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalBalance});

  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total balance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${totalBalance.toStringAsFixed(2)} RUB',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Backend returns total balance in RUB.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
