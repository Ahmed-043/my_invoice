import 'package:flutter/material.dart';
import 'invoice_preview_classic.dart';
import 'invoice_preview_modern.dart';
import 'invoice_preview_bold.dart';

class InvoicePreviewWidget extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final List<Map<String, dynamic>> services;
  final int clientInvoiceSequence;
  final bool showTracking;

  const InvoicePreviewWidget({
    super.key,
    required this.invoice,
    required this.services,
    required this.clientInvoiceSequence,
    required this.showTracking,
  });

  Color _getAccentColor(ColorScheme colorScheme) {
    final accentStr = (invoice['accentColor'] as String? ?? 'default').toLowerCase();
    switch (accentStr) {
      case 'blue':
        return Colors.indigo;
      case 'green':
        return Colors.teal;
      case 'gold':
        return Colors.amber[700]!;
      case 'red':
        return Colors.deepOrangeAccent;
      case 'default':
      default:
        return colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _getAccentColor(colorScheme);

    const double designWidth = 595.0;

    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: designWidth,
        decoration: BoxDecoration(color: colorScheme.surface),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 45),
        child: _buildTemplate(colorScheme, accent),
      ),
    );
  }

  Widget _buildTemplate(ColorScheme colorScheme, Color accent) {
    final style = (invoice['templateStyle'] as String? ?? 'classic').toLowerCase();
    switch (style) {
      case 'modern':
        return buildModernTemplate(invoice, services, clientInvoiceSequence, showTracking, colorScheme, accent);
      case 'bold':
        return buildBoldTemplate(invoice, services, clientInvoiceSequence, showTracking, colorScheme, accent);
      case 'classic':
      default:
        return buildClassicTemplate(invoice, services, clientInvoiceSequence, showTracking, colorScheme, accent);
    }
  }
}
