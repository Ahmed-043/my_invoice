import 'package:flutter/material.dart';

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
        decoration: BoxDecoration(
          color: colorScheme.surface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 45),
        child: _buildTemplate(colorScheme, accent),
      ),
    );
  }

  Widget _buildTemplate(ColorScheme colorScheme, Color accent) {
    final style = (invoice['templateStyle'] as String? ?? 'classic').toLowerCase();
    switch (style) {
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
        Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
        const SizedBox(height: 15),
        _buildBillingGrid(colorScheme, accent),
        const SizedBox(height: 15),
        Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
        const SizedBox(height: 10),
        _buildServicesTable(colorScheme, accent),
        const SizedBox(height: 10),
        Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
        const SizedBox(height: 5),
        _buildFooter(colorScheme, accent),
        const SizedBox(height: 10),
        Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
        const SizedBox(height: 10),
        _buildFinalFooter(colorScheme, accent),
      ],
    );
  }

  Widget _buildClassicHeader(ColorScheme colorScheme, Color accent) {
    final id = invoice['id'];
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
          showTracking ? "#${id.toString().padLeft(2, '0')}" : clientInvoiceSequence.toString().padLeft(2, '0'),
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
                    _infoBlock('BILLED TO', clientName, colorScheme, accent),
                    const SizedBox(height: 20),
                    _infoBlock('FROM', yourName, colorScheme, accent),
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
                    _infoBlock('ISSUED DATE', issuedDate, colorScheme, accent),
                    const SizedBox(height: 20),
                    _infoBlock('DUE DATE', dueDate, colorScheme, accent),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        _buildServicesTable(colorScheme, accent, useModernRowBg: true),
        const SizedBox(height: 20),
        Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
        const SizedBox(height: 10),
        _buildFooter(colorScheme, accent),
        const SizedBox(height: 15),
        Divider(color: accent.withValues(alpha: 0.2), thickness: 1),
        const SizedBox(height: 10),
        _buildFinalFooter(colorScheme, accent),
      ],
    );
  }

  // ─── BOLD TEMPLATE ─────────────────────────────────────────────────────────

  Widget _buildBoldTemplate(ColorScheme colorScheme, Color accent) {
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
    final clientName = invoice['clientName'] as String? ?? '';
    final yourName = invoice['yourName'] as String? ?? '';
    final issuedDate = invoice['issuedDate'] as String? ?? '';
    final dueDate = invoice['dueDate'] as String? ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoBlock('BILLED TO', clientName, colorScheme, accent),
                const SizedBox(height: 30),
                _infoBlock('FROM', yourName, colorScheme, accent),
              ],
            ),
          ),
          VerticalDivider(
            color: accent.withValues(alpha: 0.3),
            thickness: 1,
            indent: 5,
            endIndent: 5,
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoBlock('ISSUED DATE', issuedDate, colorScheme, accent),
                const SizedBox(height: 30),
                _infoBlock('DUE DATE', dueDate, colorScheme, accent),
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
    final currencySymbol = invoice['currencySymbol'] as String? ?? 'Rs';
    final discount = (invoice['discount'] as num?)?.toDouble() ?? 0.0;
    final total = (invoice['total'] as num?)?.toDouble() ?? 0.0;

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

          final serviceName = s['serviceName'] as String? ?? '';
          final quantity = s['quantity'] ?? 0;
          final itemTotal = (s['total'] as num?)?.toDouble() ?? 0.0;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: useModernRowBg && !isEven
                ? BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    serviceName,
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
                      '$quantity',
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
                      '${itemTotal.toStringAsFixed(0)} $currencySymbol',
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
        Divider(color: accent.withValues(alpha: 0.2), thickness: 1, indent: 300),
        const SizedBox(height: 15),
        _buildTotalRow('DISCOUNT', '${discount.toStringAsFixed(0)} $currencySymbol', colorScheme, accent),
        const SizedBox(height: 10),
        Divider(color: accent.withValues(alpha: 0.2), thickness: 1, indent: 200),
        const SizedBox(height: 10),
        _buildTotalRow('TOTAL', '${total.toStringAsFixed(0)} $currencySymbol', colorScheme, accent, isTotal: true),
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
    final yourName = invoice['yourName'] as String? ?? '';
    final accountNo = invoice['accountNo'] as String? ?? '';
    final paymentMethod = invoice['paymentMethod'] as String? ?? '';
    final penaltyValue = invoice['penaltyValue'] ?? 0;
    final penaltyType = invoice['penaltyType'] as String? ?? '%';
    final currencySymbol = invoice['currencySymbol'] as String? ?? 'Rs';
    final email = invoice['email'] as String? ?? '';

    final penaltyUnit = penaltyType == '%' ? '%' : currencySymbol;

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
                _paymentDetail('NAME', yourName, colorScheme, accent),
                _paymentDetail('ACC NO.', accountNo, colorScheme, accent),
                _paymentDetail('P. METHOD', paymentMethod, colorScheme, accent),
              ],
            ),
          ),
          VerticalDivider(
            color: accent.withValues(alpha: 0.3),
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
                        'A late fee of $penaltyValue$penaltyUnit will be added to any past-due balance. '
                        'Accepted payment methods are mentioned above. '
                        'If you have any questions regarding your invoice, please contact at $email',
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
    final brandName = (invoice['brandName'] as String? ?? '').toUpperCase();

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
          brandName,
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
