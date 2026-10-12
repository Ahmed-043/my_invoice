import 'package:flutter/material.dart';

Widget buildInfoBlock(String label, String value, ColorScheme colorScheme, Color accent) {
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

Widget buildBillingGrid(Map<String, dynamic> invoice, ColorScheme colorScheme, Color accent) {
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
              buildInfoBlock('BILLED TO', clientName, colorScheme, accent),
              const SizedBox(height: 30),
              buildInfoBlock('FROM', yourName, colorScheme, accent),
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
              buildInfoBlock('ISSUED DATE', issuedDate, colorScheme, accent),
              const SizedBox(height: 30),
              buildInfoBlock('DUE DATE', dueDate, colorScheme, accent),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildServicesTable(
  Map<String, dynamic> invoice,
  List<Map<String, dynamic>> services,
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

  return Column(
    children: [
      Container(
        padding: useBoldHeader ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : EdgeInsets.zero,
        decoration: useBoldHeader ? BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)) : null,
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text('SERVICES', style: TextStyle(color: headerTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Center(
                child: Text('QUANTITY', style: TextStyle(color: headerTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('AMOUNT', style: TextStyle(color: headerTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ...services.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        final isEven = idx % 2 == 0;

        final serviceName = s['serviceName'] as String? ?? s['name'] as String? ?? '';
        final quantity = s['quantity'] ?? 0;
        final itemTotal = (s['total'] as num?)?.toDouble() ?? (s['unit_price'] as num?)?.toDouble() ?? 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: useModernRowBg && !isEven
              ? BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(8))
              : null,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(serviceName, style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w300)),
              ),
              Expanded(
                child: Center(
                  child: Text('$quantity', style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w300)),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('${itemTotal.toStringAsFixed(0)} $currencySymbol',
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w300)),
                ),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 10),
      Divider(color: accent.withValues(alpha: 0.2), thickness: 1, indent: 300),
      const SizedBox(height: 15),
      buildTotalRow('DISCOUNT', '${discount.toStringAsFixed(0)} $currencySymbol', colorScheme, accent),
      const SizedBox(height: 10),
      Divider(color: accent.withValues(alpha: 0.2), thickness: 1, indent: 200),
      const SizedBox(height: 10),
      buildTotalRow('TOTAL', '${total.toStringAsFixed(0)} $currencySymbol', colorScheme, accent, isTotal: true),
    ],
  );
}

Widget buildTotalRow(String label, String value, ColorScheme colorScheme, Color accent, {bool isTotal = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(label, style: TextStyle(color: isTotal ? accent : colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(width: 60),
      Text(value, style: TextStyle(color: isTotal ? accent : colorScheme.onSurface, fontSize: isTotal ? 20 : 15, fontWeight: isTotal ? FontWeight.bold : FontWeight.w300)),
    ],
  );
}

Widget buildFooter(Map<String, dynamic> invoice, ColorScheme colorScheme, Color accent) {
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
              Text('PAYMENT INFO', style: TextStyle(color: accent == colorScheme.onSurface ? colorScheme.onSurface : accent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              _paymentDetail('NAME', yourName, colorScheme),
              _paymentDetail('ACC NO.', accountNo, colorScheme),
              _paymentDetail('P. METHOD', paymentMethod, colorScheme),
            ],
          ),
        ),
        VerticalDivider(color: accent.withValues(alpha: 0.3), thickness: 1, indent: 5, endIndent: 5),
        const SizedBox(width: 30),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Please note that all payments are '),
                const TextSpan(text: 'non-refundable', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                TextSpan(
                  text: '. Invoices are due within one day of the invoice date. A late fee of $penaltyValue$penaltyUnit will be added to any past-due balance. If you have any questions, contact $email',
                ),
              ],
            ),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, height: 1.5, fontWeight: FontWeight.w300),
          ),
        ),
      ],
    ),
  );
}

Widget _paymentDetail(String label, String value, ColorScheme colorScheme) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w300)),
      ],
    ),
  );
}

Widget buildFinalFooter(Map<String, dynamic> invoice, ColorScheme colorScheme, Color accent) {
  final brandName = (invoice['brandName'] as String? ?? '').toUpperCase();

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('THANK YOU!', style: TextStyle(color: accent, fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: 1.2)),
      Text(brandName, style: TextStyle(color: colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    ],
  );
}
