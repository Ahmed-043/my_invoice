import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'stat_card.dart';

class FinancialSummaryDashboard extends StatelessWidget {
  final bool hasInvoices;
  final double collectionProgress;
  final double totalReceived;
  final double totalReceivables;
  final int overdueCount;

  /// Prefix shown for monetary values (e.g. "Rs").
  final String currencyPrefix;

  const FinancialSummaryDashboard({
    super.key,
    required this.hasInvoices,
    required this.collectionProgress,
    required this.totalReceived,
    required this.totalReceivables,
    required this.overdueCount,
    this.currencyPrefix = 'Rs',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.4),
            colorScheme.secondaryContainer.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Summary',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (hasInvoices)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(collectionProgress * 100).toStringAsFixed(0)}% Collected',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Received',
                  value: '$currencyPrefix ${NumberFormat.decimalPattern().format(totalReceived)}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: '$currencyPrefix ${NumberFormat.decimalPattern().format(totalReceivables)}',
                  icon: Icons.hourglass_bottom_rounded,
                  color: colorScheme.tertiary,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Overdue',
                  value: NumberFormat.decimalPattern().format(overdueCount),
                  icon: Icons.error_outline_rounded,
                  color: colorScheme.error,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          if (hasInvoices) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: collectionProgress,
                minHeight: 8,
                backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                color: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

