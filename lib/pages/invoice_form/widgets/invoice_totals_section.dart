import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/labeled_text_field.dart';
import 'invoice_form_section_card.dart';

class InvoiceTotalsSection extends StatelessWidget {
  final TextEditingController discountController;
  final String currencySymbol;
  final double subtotal;
  final double total;
  final VoidCallback onCalculateTotal;

  const InvoiceTotalsSection({
    super.key,
    required this.discountController,
    required this.currencySymbol,
    required this.subtotal,
    required this.total,
    required this.onCalculateTotal,
  });

  @override
  Widget build(BuildContext context) {
    return InvoiceFormSectionCard(
      title: "Totals",
      child: Column(
        children: [
          LabeledTextField(
            controller: discountController,
            label: "Discount / Adjustment",
            capitalization: TextCapitalization.none,
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onCalculateTotal(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal", style: TextStyle(fontSize: 16)),
              Text("$currencySymbol ${subtotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Grand Total", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                "$currencySymbol ${total.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
