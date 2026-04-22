import 'package:flutter/material.dart';

import '../models/wallet.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import 'create_wallet_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<WalletModel> _wallets = const [];
  String? _selectedWalletName;
  String _operationType = 'expense';
  bool _isLoadingWallets = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    setState(() {
      _isLoadingWallets = true;
    });

    try {
      final wallets = await ApiService.getWallets();
      if (!mounted) {
        return;
      }

      setState(() {
        _wallets = wallets;
        _selectedWalletName = wallets.isEmpty ? null : wallets.first.name;
        _isLoadingWallets = false;
      });
    } on ApiException catch (error) {
      _showMessage(error.message);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingWallets = false;
      });
    } catch (_) {
      _showMessage('Could not load wallets.');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingWallets = false;
      });
    }
  }

  Future<void> _createWallet() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
    );

    if (created == true) {
      await _loadWallets();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedWalletName == null ||
        _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    try {
      if (_operationType == 'expense') {
        await ApiService.addExpense(
          walletName: _selectedWalletName!,
          amount: amount,
          description: _descriptionController.text,
        );
      } else {
        await ApiService.addIncome(
          walletName: _selectedWalletName!,
          amount: amount,
          description: _descriptionController.text,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not save operation.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New operation')),
      body: SafeArea(
        child: _isLoadingWallets
            ? const Center(child: CircularProgressIndicator())
            : _wallets.isEmpty
                ? _NoWalletState(onCreateWallet: _createWallet)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'expense',
                                label: Text('Expense'),
                                icon: Icon(Icons.north_east),
                              ),
                              ButtonSegment(
                                value: 'income',
                                label: Text('Income'),
                                icon: Icon(Icons.south_west),
                              ),
                            ],
                            selected: {_operationType},
                            onSelectionChanged: (value) {
                              setState(() {
                                _operationType = value.first;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedWalletName,
                            items: _wallets
                                .map(
                                  (wallet) => DropdownMenuItem(
                                    value: wallet.name,
                                    child: Text(
                                        '${wallet.name} (${wallet.currency})'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedWalletName = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Wallet',
                              prefixIcon:
                                  Icon(Icons.account_balance_wallet_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(
                                  (value ?? '').replaceAll(',', '.'));
                              if (parsed == null) {
                                return 'Введите сумму';
                              }
                              if (parsed <= 0) {
                                return 'Сумма должна быть больше нуля';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLength: 255,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(Icons.edit_note),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text(
                                      _operationType == 'expense'
                                          ? 'Save expense'
                                          : 'Save income',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _NoWalletState extends StatelessWidget {
  const _NoWalletState({
    required this.onCreateWallet,
  });

  final Future<void> Function() onCreateWallet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 44),
            const SizedBox(height: 12),
            Text(
              'Сначала нужен кошелек',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Backend привязывает операции к конкретному кошельку, поэтому сначала создайте его.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreateWallet,
              icon: const Icon(Icons.add),
              label: const Text('Create wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
