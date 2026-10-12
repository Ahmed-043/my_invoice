import 'package:flutter/material.dart';
import 'invoice_preview_sections.dart';

Widget buildClassicTemplate(
  Map<String, dynamic> invoice,
  List<Map<String, dynamic>> services,
  int clientInvoiceSequence,
  bool showTracking,
  ColorScheme colorScheme,
  Color accent,
) {
  final id = invoice['id'];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'INVOICE',
            style: TextStyle(
              fontSize: 60,
              color: accent,
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
            ),
          ),
          Text(
            showTracking ? "#${id.toString().padLeft(2, '0')}" : clientInvoiceSequence.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 60,
              color: accent,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
      const SizedBox(height: 15),
      buildBillingGrid(invoice, colorScheme, accent),
      const SizedBox(height: 15),
      Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
      const SizedBox(height: 10),
      buildServicesTable(invoice, services, colorScheme, accent),
      const SizedBox(height: 10),
      Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
      const SizedBox(height: 5),
      buildFooter(invoice, colorScheme, accent),
      const SizedBox(height: 10),
      Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
      const SizedBox(height: 10),
      buildFinalFooter(invoice, colorScheme, accent),
    ],
  );
}
