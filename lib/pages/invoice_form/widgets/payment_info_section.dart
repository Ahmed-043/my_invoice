import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/addable_autocomplete_field.dart';
import '../../widgets/labeled_text_field.dart';
import 'invoice_form_section_card.dart';

class PaymentInfoSection extends StatelessWidget {
  final TextEditingController accountController;
  final FocusNode accountFocusNode;
  final List<String> accounts;
  final bool showAccountAddButton;
  final VoidCallback onAddAccount;
  final ValueChanged<String> onAccountChanged;

  final TextEditingController paymentController;
  final FocusNode paymentFocusNode;
  final List<String> paymentMethods;
  final bool showPaymentAddButton;
  final VoidCallback onAddPaymentMethod;
  final ValueChanged<String> onPaymentMethodSelected;

  final String currencyCode;
  final ValueChanged<String?> onCurrencyChanged;

  final TextEditingController penaltyController;
  final String penaltyType;
  final ValueChanged<String?> onPenaltyTypeChanged;

  const PaymentInfoSection({
    super.key,
    required this.accountController,
    required this.accountFocusNode,
    required this.accounts,
    required this.showAccountAddButton,
    required this.onAddAccount,
    required this.onAccountChanged,
    required this.paymentController,
    required this.paymentFocusNode,
    required this.paymentMethods,
    required this.showPaymentAddButton,
    required this.onAddPaymentMethod,
    required this.onPaymentMethodSelected,
    required this.currencyCode,
    required this.onCurrencyChanged,
    required this.penaltyController,
    required this.penaltyType,
    required this.onPenaltyTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InvoiceFormSectionCard(
      title: "Payment Information",
      child: Column(
        children: [
          AddableAutocompleteField(
            controller: accountController,
            focusNode: accountFocusNode,
            label: "Account No / IBAN",
            options: accounts,
            showAddButton: showAccountAddButton,
            onAdd: onAddAccount,
            capitalization: TextCapitalization.none,
            onChanged: onAccountChanged,
          ),
          const SizedBox(height: 24),

          Text("Payment Method", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          Autocomplete<String>(
            focusNode: paymentFocusNode,
            textEditingController: paymentController,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              return paymentMethods.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: onPaymentMethodSelected,
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController fieldController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted,
            ) {
              return TextField(
                controller: fieldController,
                focusNode: fieldFocusNode,
                decoration: InputDecoration(
                  labelText: "Type or select payment method",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: showPaymentAddButton && fieldFocusNode.hasFocus
                      ? IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          tooltip: "Add new payment method",
                          onPressed: onAddPaymentMethod,
                        )
                      : null,
                ),
                onSubmitted: (_) => onAddPaymentMethod(),
              );
            },
          ),

          const SizedBox(height: 24),

          Column(
            children: [
              DropdownButtonFormField<String>(
                value: currencyCode,
                decoration: InputDecoration(
                  labelText: "Currency",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: "PKR", child: Text("PKR - Pakistani Rupee - PKR")),
                  DropdownMenuItem(value: "USD", child: Text("USD - United States Dollar - \$")),
                  DropdownMenuItem(value: "EUR", child: Text("EUR - Euro - €")),
                  DropdownMenuItem(value: "GBP", child: Text("GBP - British Pound - £")),
                  DropdownMenuItem(value: "AED", child: Text("AED - UAE Dirham - د.إ")),
                  DropdownMenuItem(value: "SAR", child: Text("SAR - Saudi Riyal - ر.س")),
                  DropdownMenuItem(value: "CAD", child: Text("CAD - Canadian Dollar - \$")),
                  DropdownMenuItem(value: "AUD", child: Text("AUD - Australian Dollar - \$")),
                  DropdownMenuItem(value: "INR", child: Text("INR - Indian Rupee - ₹")),
                  DropdownMenuItem(value: "JPY", child: Text("JPY - Japanese Yen - ¥")),
                  DropdownMenuItem(value: "CNY", child: Text("CNY - Chinese Yuan - ¥ / 元")),
                  DropdownMenuItem(value: "CHF", child: Text("CHF - Swiss Franc - CHF")),
                  DropdownMenuItem(value: "SGD", child: Text("SGD - Singapore Dollar - \$")),
                  DropdownMenuItem(value: "MYR", child: Text("MYR - Malaysian Ringgit - RM")),
                  DropdownMenuItem(value: "TRY", child: Text("TRY - Turkish Lira - ₺")),
                ],
                onChanged: onCurrencyChanged,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: LabeledTextField(
                      controller: penaltyController,
                      label: "Late Fee Penalty",
                      capitalization: TextCapitalization.none,
                      keyboard: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: penaltyType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Type",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: "%", child: Text("Percentage (%)")),
                        DropdownMenuItem(value: "Direct", child: Text("Fixed Amount")),
                      ],
                      onChanged: onPenaltyTypeChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
