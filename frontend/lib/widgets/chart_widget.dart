import 'package:flutter/material.dart';

import '../models/operation.dart';

class ChartWidget extends StatelessWidget {
  const ChartWidget({
    super.key,
    required this.operations,
  });

  final List<OperationModel> operations;

  @override
  Widget build(BuildContext context) {
    final groups = _buildDailyTotals(operations);
    final maxValue = groups.fold<double>(
      0,
      (currentMax, item) => item.value > currentMax ? item.value : currentMax,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: groups.map((item) {
        final heightFactor =
            maxValue == 0 ? 0.18 : (item.value / maxValue).clamp(0.18, 1.0);
        final barColor =
            item.value == 0 ? Colors.grey.shade300 : const Color(0xFF10403B);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 86 * heightFactor,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_DailyTotal> _buildDailyTotals(List<OperationModel> operations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final amount = operations.where((operation) {
        final operationDay = DateTime(
          operation.createdAt.year,
          operation.createdAt.month,
          operation.createdAt.day,
        );
        return operation.isExpense && operationDay == day;
      }).fold<double>(0, (sum, operation) => sum + operation.amount);

      return _DailyTotal(
        label: _weekdayLabel(day.weekday),
        value: amount,
      );
    });
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }
}

class _DailyTotal {
  const _DailyTotal({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}
