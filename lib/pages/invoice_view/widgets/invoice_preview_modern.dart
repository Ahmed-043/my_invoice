import 'package:flutter/material.dart';
import 'invoice_preview_sections.dart';

Widget buildModernTemplate(
  Map<String, dynamic> invoice,
  List<Map<String, dynamic>> services,
  int clientInvoiceSequence,
  bool showTracking,
  ColorScheme colorScheme,
  Color accent,
) {
  final id = invoice['id'];
  final brandName = (invoice['brandName'] as String? ?? '').toUpperCase();
  final clientName = invoice['clientName'] as String? ?? '';
  final yourName = invoice['yourName'] as String? ?? '';
  final issuedDate = invoice['issuedDate'] as String? ?? '';
  final dueDate = invoice['dueDate'] as String? ?? '';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INVOICE',
                style: TextStyle(
                  fontSize: 48,
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                brandName,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              showTracking
                  ? "ID #${id.toString().padLeft(2, '0')}"
                  : clientInvoiceSequence.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 20,
                color: accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 25),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInfoBlock('BILLED TO', clientName, colorScheme, accent),
                  const SizedBox(height: 20),
                  buildInfoBlock('FROM', yourName, colorScheme, accent),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInfoBlock('ISSUED DATE', issuedDate, colorScheme, accent),
                  const SizedBox(height: 20),
                  buildInfoBlock('DUE DATE', dueDate, colorScheme, accent),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 25),
      buildServicesTable(invoice, services, colorScheme, accent, useModernRowBg: true),
      const SizedBox(height: 20),
      Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
      const SizedBox(height: 10),
      buildFooter(invoice, colorScheme, accent),
      const SizedBox(height: 15),
      Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
      const SizedBox(height: 10),
      buildFinalFooter(invoice, colorScheme, accent),
    ],
  );
}
