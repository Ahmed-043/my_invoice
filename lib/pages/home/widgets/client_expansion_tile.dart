import 'package:flutter/material.dart';
import '../../../backend/supabase/supabase_service.dart';
import 'invoice_tile.dart';

class ClientExpansionTile extends StatelessWidget {
  final String clientName;
  final List<Map<String, dynamic>> invoices;
  final int Function(Map<String, dynamic> invoice) getSequence;
  final VoidCallback onRefreshNeeded;
  final SupabaseService supabaseService;

  const ClientExpansionTile({
    super.key,
    required this.clientName,
    required this.invoices,
    required this.getSequence,
    required this.onRefreshNeeded,
    required this.supabaseService,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = invoices.fold<double>(0, (sum, inv) => sum + ((inv['total'] as num?)?.toDouble() ?? 0.0));
    final pendingAmount = invoices
        .where((inv) => (inv['status'] as String? ?? '').toLowerCase() != 'paid')
        .fold<double>(0, (sum, inv) {
      final total = (inv['total'] as num?)?.toDouble() ?? 0.0;
      final paid = (inv['paidAmount'] as num?)?.toDouble() ?? 0.0;
      return sum + (total - paid);
    });
    final pendingCount = invoices.where((inv) => (inv['status'] as String? ?? '').toLowerCase() != 'paid').length;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencySymbol = invoices.isNotEmpty ? (invoices.first['currencySymbol'] as String? ?? '\$') : '\$';

    return Card(
      key: ValueKey(clientName),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          childrenPadding: const EdgeInsets.only(bottom: 5),
          backgroundColor: colorScheme.surfaceBright,
          collapsedBackgroundColor: colorScheme.surfaceContainerHigh,
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            clientName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                "${invoices.length} project${invoices.length == 1 ? '' : 's'}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$pendingCount pending",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$currencySymbol ${totalAmount.toStringAsFixed(0)}",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              if (pendingAmount > 0)
                Text(
                  "Due: $currencySymbol ${pendingAmount.toStringAsFixed(0)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          children: invoices.map((inv) {
            return InvoiceTile(
              invoice: inv,
              clientInvoiceSequence: getSequence(inv),
              onRefreshNeeded: onRefreshNeeded,
              supabaseService: supabaseService,
            );
          }).toList(),
        ),
      ),
    );
  }
}
