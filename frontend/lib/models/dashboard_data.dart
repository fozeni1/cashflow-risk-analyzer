import 'operation.dart';
import 'wallet.dart';

class DashboardData {
  final double totalBalance;
  final List<Wallet> wallets;
  final List<Operation> operations;

  DashboardData({
    required this.totalBalance,
    required this.wallets,
    required this.operations,
  });
}
