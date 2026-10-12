import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../backend/supabase/supabase_service.dart';
import '../../invoice_view/invoice_preview_screen.dart';

class InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final int clientInvoiceSequence;
  final VoidCallback onRefreshNeeded;
  final SupabaseService supabaseService;

  const InvoiceTile({
    super.key,
    required this.invoice,
    required this.clientInvoiceSequence,
    required this.onRefreshNeeded,
    required this.supabaseService,
  });

  Future<void> _showPaymentDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final id = invoice['id'];
    final paidAmount = (invoice['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final total = (invoice['total'] as num?)?.toDouble() ?? 0.0;
    final currencySymbol = invoice['currencySymbol'] as String? ?? '\$';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Payment for Project #${id.toString().substring(0, 8)}"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Current: ${paidAmount.toStringAsFixed(2)} / ${total.toStringAsFixed(2)} $currencySymbol",
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixText: "$currencySymbol ",
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter an amount";
                  if (double.tryParse(value) == null) return "Invalid number";
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text("Apply Payment"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final amountText = amountController.text.trim();
      final amount = double.tryParse(amountText);

      if (amount != null) {
        try {
          await supabaseService.createPaymentEntry(
            projectId: id.toString(),
            amount: amount,
            paymentMethod: 'Bank Transfer',
          );
          onRefreshNeeded();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Payment error: $e"), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final id = invoice['id'];
    final displayId = id.toString().length > 8 ? id.toString().substring(0, 8) : id.toString();
    final status = (invoice['status'] as String? ?? 'pending').toLowerCase();
    final currencySymbol = invoice['currencySymbol'] as String? ?? '\$';
    final total = (invoice['total'] as num?)?.toDouble() ?? 0.0;
    final dueDateStr = invoice['dueDate'] as String? ?? '';

    final isPaid = status == 'paid';
    final isPartial = status == 'partially_paid';
    final isPending = !isPaid && !isPartial;

    bool isDue = false;
    if (dueDateStr.isNotEmpty) {
      try {
        final dueDate = DateFormat("yyyy-MM-dd").parse(dueDateStr);
        isDue = dueDate.isBefore(DateTime.now());
      } catch (_) {}
    }

    final services = List<Map<String, dynamic>>.from(invoice['rawServices'] ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Hero(
        tag: "invoice-$id",
        child: Card(
          elevation: isPending ? 2 : 1,
          shadowColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isPending
              ? colorScheme.primaryContainer
              : isPartial
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoiceViewScreen(
                    invoice: invoice,
                    services: services,
                    clientInvoiceSequence: clientInvoiceSequence,
                    callBack: onRefreshNeeded,
                  ),
                ),
              );
            },
            onLongPress: () => _showPaymentDialog(context),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPaid
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : isPartial
                      ? colorScheme.tertiary.withValues(alpha: 0.15)
                      : isDue
                      ? colorScheme.error.withValues(alpha: 0.12)
                      : colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle_rounded
                      : isPartial
                      ? Icons.hourglass_bottom_rounded
                      : Icons.schedule_rounded,
                  color: isPaid
                      ? colorScheme.primary
                      : isPartial
                      ? isDue
                      ? colorScheme.error
                      : colorScheme.tertiary
                      : isDue
                      ? colorScheme.error
                      : colorScheme.primary,
                  size: 28,
                ),
              ),
              title: Text(
                "Project #$displayId",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "$currencySymbol ${total.toStringAsFixed(0)} • ${status.toUpperCase()}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isPaid
                      ? colorScheme.primary
                      : isPartial
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.payment_rounded, color: colorScheme.primary),
                onPressed: () => _showPaymentDialog(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
