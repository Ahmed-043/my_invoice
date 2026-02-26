import 'package:flutter/material.dart';
import '../../core/models/invoice_model.dart';
import '../../core/models/service_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const double designWidth = 595.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          clipBehavior: Clip.hardEdge,

          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: designWidth,
            decoration: BoxDecoration(
              color: colorScheme.surface,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(colorScheme),
                const SizedBox(height: 5),
                Divider(color: colorScheme.onSurface.withOpacity(0.2), thickness: 1), // ← changed
                const SizedBox(height: 15),
                _buildBillingGrid(colorScheme),
                const SizedBox(height: 15),
                Divider(color: colorScheme.onSurface.withOpacity(0.2), thickness: 1),
                const SizedBox(height: 10),
                _buildServicesTable(colorScheme),
                const SizedBox(height: 10),
                Divider(color: colorScheme.onSurface.withOpacity(0.2), thickness: 1),
                const SizedBox(height: 5),
                _buildFooter(colorScheme),
                const SizedBox(height: 10),
                Divider(color: colorScheme.onSurface.withOpacity(0.2), thickness: 1),
                const SizedBox(height: 10),
                _buildFinalFooter(colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'INVOICE',
          style: TextStyle(
            fontSize: 60,
            color: colorScheme.onSurface,           // ← changed
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
        Text(
          showTracking ? "#${invoice.id.toString().padLeft(2, '0')}" : clientInvoiceSequence.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 60,
            color: colorScheme.onSurface,           // ← changed
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingGrid(ColorScheme colorScheme) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoBlock("BILLED TO", invoice.clientName, colorScheme),
                const SizedBox(height: 30),
                _infoBlock("FROM", invoice.yourName, colorScheme),
              ],
            ),
          ),
          VerticalDivider(
            color: colorScheme.onSurfaceVariant.withOpacity(0.4), // ← changed
            thickness: 1,
            indent: 5,
            endIndent: 5,
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoBlock("ISSUED DATE", invoice.issuedDate, colorScheme),
                const SizedBox(height: 30),
                _infoBlock("DUE DATE", invoice.dueDate, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,    // ← changed
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,           // ← changed
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTable(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                "SERVICES",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "QUANTITY",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "AMOUNT",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...services.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  s.serviceName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "${s.quantity}",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${s.total.toStringAsFixed(0)} ${invoice.currencySymbol}",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 10),
        Divider(color: colorScheme.onSurface.withOpacity(0.2), thickness: 1,indent: 300),
        const SizedBox(height: 15),
        _buildTotalRow("DISCOUNT", "${invoice.discount} ${invoice.currencySymbol}", colorScheme),
        const SizedBox(height: 15),
        Divider(color: colorScheme.onSurface.withOpacity(0.2), thickness: 1),
        const SizedBox(height: 5),
        _buildTotalRow("TOTAL", "${invoice.total} ${invoice.currencySymbol}", colorScheme, isTotal: true),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, ColorScheme colorScheme, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 60),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PAYMENT INFO",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                _paymentDetail("NAME", invoice.yourName, colorScheme),
                _paymentDetail("ACC NO.", invoice.accountNo, colorScheme),
                _paymentDetail("P. METHOD", invoice.paymentMethod, colorScheme),
              ],
            ),
          ),
          VerticalDivider(
            color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            thickness: 1,
            indent: 5,
            endIndent: 5,
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: "Please note that all payments are "),
                  const TextSpan(
                    text: "non-refundable",
                    style: TextStyle(fontWeight: FontWeight.w800,fontSize: 12), // Bold specific phrase
                  ),
                  TextSpan(
                    text: ". Invoices are due within one day of the invoice date. "
                        "A late fee of ${invoice.penaltyValue}${invoice.penaltyType == '%' ? '%' : invoice.currencySymbol} will be added to any past-due balance. "
                        "Accepted payment methods are mentioned above. "
                        "If you have any questions regarding your invoice, please contact at ${invoice.email}",
                  ),
                ],
              ),
              textAlign: TextAlign.start, // Justify the text block
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentDetail(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalFooter(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "THANK YOU!",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 42,
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
       // const Expanded(child: SizedBox()),

      ],
    );
  }
}