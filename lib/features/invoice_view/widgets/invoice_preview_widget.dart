import 'package:flutter/material.dart';

import '../../../core/models/invoice_model.dart';
import '../../../core/models/service_model.dart';

class InvoicePreviewWidget extends StatelessWidget {
  final Invoice invoice;
  final List<ServiceItem> services;
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
    switch (invoice.accentColor.toLowerCase()) {
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
        decoration: BoxDecoration(
          color: colorScheme.surface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 45),
        child: _buildTemplate(colorScheme, accent),
      ),
    );
  }

  Widget _buildTemplate(ColorScheme colorScheme, Color accent) {
    switch (invoice.templateStyle.toLowerCase()) {
      case 'modern':
        return _buildModernTemplate(colorScheme, accent);
      case 'bold':
        return _buildBoldTemplate(colorScheme, accent);
      case 'classic':
      default:
        return _buildClassicTemplate(colorScheme, accent);
    }
  }

  // ─── CLASSIC TEMPLATE ──────────────────────────────────────────────────────

  Widget _buildClassicTemplate(ColorScheme colorScheme, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildClassicHeader(colorScheme, accent),
        const SizedBox(height: 5),
        Divider(color: accent.withOpacity(0.2), thickness: 1),
        const SizedBox(height: 15),
        _buildBillingGrid(colorScheme, accent),
        const SizedBox(height: 15),
        Divider(color: accent.withOpacity(0.2), thickness: 1),
        const SizedBox(height: 10),
        _buildServicesTable(colorScheme, accent),
        const SizedBox(height: 10),
        Divider(color: accent.withOpacity(0.2), thickness: 1),
        const SizedBox(height: 5),
        _buildFooter(colorScheme, accent),
        const SizedBox(height: 10),
        Divider(color: accent.withOpacity(0.2), thickness: 1),
        const SizedBox(height: 10),
        _buildFinalFooter(colorScheme, accent),
      ],
    );
  }

  Widget _buildClassicHeader(ColorScheme colorScheme, Color accent) {
    return Row(
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
          showTracking ? "#${invoice.id.toString().padLeft(2, '0')}" : clientInvoiceSequence.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 60,
            color: accent,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ─── MODERN TEMPLATE ───────────────────────────────────────────────────────

  Widget _buildModernTemplate(ColorScheme colorScheme, Color accent) {
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
                  invoice.brandName.toUpperCase(),
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
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Text(
                showTracking
                    ? "ID #${invoice.id.toString().padLeft(2, '0')}"
                    : "${clientInvoiceSequence.toString().padLeft(2, '0')}",
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
                  color: colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoBlock('BILLED TO', invoice.clientName, colorScheme, accent),
                    const SizedBox(height: 20),
                    _infoBlock('FROM', invoice.yourName, colorScheme, accent),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoBlock('ISSUED DATE', invoice.issuedDate, colorScheme, accent),
                    const SizedBox(height: 20),
                    _infoBlock('DUE DATE', invoice.dueDate, colorScheme, accent),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        _buildServicesTable(colorScheme, accent, useModernRowBg: true),
        const SizedBox(height: 20),
        Divider(color: accent.withOpacity(0.2), thickness: 1),
        const SizedBox(height: 10),
        _buildFooter(colorScheme, accent),
        const SizedBox(height: 15),
        Divider(color: accent.withOpacity(0.2), thickness: 1),
        const SizedBox(height: 10),
        _buildFinalFooter(colorScheme, accent),
      ],
    );
  }

  // ─── BOLD TEMPLATE ─────────────────────────────────────────────────────────

  Widget _buildBoldTemplate(ColorScheme colorScheme, Color accent) {
    final bannerTextColor = accent.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

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
                    invoice.brandName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: bannerTextColor.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Text(
                showTracking
                    ? "ID #${invoice.id.toString().padLeft(2, '0')}"
                    : "${clientInvoiceSequence.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 24,
                  color: bannerTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildBillingGrid(colorScheme, accent),
        const SizedBox(height: 20),
        Divider(color: accent, thickness: 2),
        const SizedBox(height: 15),
        _buildServicesTable(colorScheme, accent, useBoldHeader: true),
        const SizedBox(height: 15),
        Divider(color: accent, thickness: 2),
        const SizedBox(height: 20),
        _buildFooter(colorScheme, accent),
        const SizedBox(height: 20),
        _buildFinalFooter(colorScheme, accent),
      ],
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildBillingGrid(ColorScheme colorScheme, Color accent) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoBlock('BILLED TO', invoice.clientName, colorScheme, accent),
                const SizedBox(height: 30),
                _infoBlock('FROM', invoice.yourName, colorScheme, accent),
              ],
            ),
          ),
          VerticalDivider(
            color: accent.withOpacity(0.3),
            thickness: 1,
            indent: 5,
            endIndent: 5,
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoBlock('ISSUED DATE', invoice.issuedDate, colorScheme, accent),
                const SizedBox(height: 30),
                _infoBlock('DUE DATE', invoice.dueDate, colorScheme, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value, ColorScheme colorScheme, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accent == colorScheme.onSurface ? colorScheme.onSurfaceVariant : accent,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTable(
    ColorScheme colorScheme,
    Color accent, {
    bool useModernRowBg = false,
    bool useBoldHeader = false,
  }) {
    final headerTextColor = useBoldHeader
        ? (accent.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : (accent == colorScheme.onSurface ? colorScheme.onSurfaceVariant : accent);

    final headerRow = Container(
      padding: useBoldHeader ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : EdgeInsets.zero,
      decoration: useBoldHeader
          ? BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'SERVICES',
              style: TextStyle(
                color: headerTextColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'QUANTITY',
                style: TextStyle(
                  color: headerTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'AMOUNT',
                style: TextStyle(
                  color: headerTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        headerRow,
        const SizedBox(height: 10),
        ...services.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          final isEven = idx % 2 == 0;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: useModernRowBg && !isEven
                ? BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    s.serviceName,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${s.quantity}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${s.total.toStringAsFixed(0)} ${invoice.currencySymbol}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        Divider(color: accent.withOpacity(0.2), thickness: 1, indent: 300),
        const SizedBox(height: 15),
        _buildTotalRow('DISCOUNT', '${invoice.discount.toStringAsFixed(0)} ${invoice.currencySymbol}', colorScheme, accent),
        const SizedBox(height: 10),
        Divider(color: accent.withOpacity(0.2), thickness: 1, indent: 200),
        const SizedBox(height: 10),
        _buildTotalRow('TOTAL', '${invoice.total.toStringAsFixed(0)} ${invoice.currencySymbol}', colorScheme, accent, isTotal: true),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, ColorScheme colorScheme, Color accent, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? accent : colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 60),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? accent : colorScheme.onSurface,
            fontSize: isTotal ? 20 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colorScheme, Color accent, {bool useModernStyle = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAYMENT INFO',
                  style: TextStyle(
                    color: accent == colorScheme.onSurface ? colorScheme.onSurface : accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                _paymentDetail('NAME', invoice.yourName, colorScheme, accent),
                _paymentDetail('ACC NO.', invoice.accountNo, colorScheme, accent),
                _paymentDetail('P. METHOD', invoice.paymentMethod, colorScheme, accent),
              ],
            ),
          ),
          VerticalDivider(
            color: accent.withOpacity(0.3),
            thickness: 1,
            indent: 5,
            endIndent: 5,
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Please note that all payments are '),
                  const TextSpan(
                    text: 'non-refundable',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  TextSpan(
                    text:
                        '. Invoices are due within one day of the invoice date. '
                        'A late fee of ${invoice.penaltyValue}${invoice.penaltyType == '%' ? '%' : invoice.currencySymbol} will be added to any past-due balance. '
                        'Accepted payment methods are mentioned above. '
                        'If you have any questions regarding your invoice, please contact at ${invoice.email}',
                  ),
                ],
              ),
              textAlign: TextAlign.start,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentDetail(String label, String value, ColorScheme colorScheme, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalFooter(ColorScheme colorScheme, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'THANK YOU!',
          style: TextStyle(
            color: accent,
            fontSize: 36,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          invoice.brandName.toUpperCase(),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

