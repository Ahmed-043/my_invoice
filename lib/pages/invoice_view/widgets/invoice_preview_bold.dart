import 'package:flutter/material.dart';
import 'invoice_preview_sections.dart';

Widget buildBoldTemplate(
  Map<String, dynamic> invoice,
  List<Map<String, dynamic>> services,
  int clientInvoiceSequence,
  bool showTracking,
  ColorScheme colorScheme,
  Color accent,
) {
  final bannerTextColor = accent.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  final id = invoice['id'];
  final brandName = (invoice['brandName'] as String? ?? '').toUpperCase();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVOICE',
                  style: TextStyle(
                    fontSize: 32,
                    color: bannerTextColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  brandName,
                  style: TextStyle(
                    fontSize: 12,
                    color: bannerTextColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            Text(
              showTracking
                  ? "ID #${id.toString().padLeft(2, '0')}"
                  : clientInvoiceSequence.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 24,
                color: bannerTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      buildBillingGrid(invoice, colorScheme, accent),
      const SizedBox(height: 20),
      Divider(color: accent, thickness: 2),
      const SizedBox(height: 15),
      buildServicesTable(invoice, services, colorScheme, accent, useBoldHeader: true),
      const SizedBox(height: 15),
      Divider(color: accent, thickness: 2),
      const SizedBox(height: 20),
      buildFooter(invoice, colorScheme, accent),
      const SizedBox(height: 20),
      buildFinalFooter(invoice, colorScheme, accent),
    ],
  );
}
