import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/invoice_repository.dart';
import '../../core/models/invoice_model.dart';
import '../../core/models/service_model.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class ServiceRowData {
  final nameController = TextEditingController();
  final quantityController = TextEditingController(text: "1");
  final priceController = TextEditingController(text: "0");
  final FocusNode focusNode = FocusNode();
  bool showAddButton = false;
  double total = 0;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    focusNode.dispose();
  }
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final repo = InvoiceRepository();

  // Controllers for main fields
  final clientController = TextEditingController();
  final yourNameController = TextEditingController();
  final brandController = TextEditingController();
  final accountController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final discountController = TextEditingController(text: "0");
  final penaltyController = TextEditingController(text: "0");

  // Payment method fields
  final _paymentController = TextEditingController();
  final _paymentFocusNode = FocusNode();
  List<String> _paymentMethods = ["Bank Transfer", "Cash", "EasyPaisa", "JazzCash"];
  String _selectedPayment = "Bank Transfer";
  bool _showPaymentAddButton = false;

  // Saved lists for autocomplete
  List<String> _clientNames = [];
  List<String> _yourNames = [];
  List<String> _brandNames = [];
  List<String> _accounts = [];
  List<String> _emails = [];
  List<String> _phones = [];
  List<String> _serviceNames = [];

  // Add button visibility flags
  bool _showClientAddButton = false;
  bool _showYourNameAddButton = false;
  bool _showBrandAddButton = false;
  bool _showAccountAddButton = false;
  bool _showEmailAddButton = false;
  bool _showPhoneAddButton = false;

  // Focus nodes
  final _clientFocusNode = FocusNode();
  final _yourNameFocusNode = FocusNode();
  final _brandFocusNode = FocusNode();
  final _accountFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  String currencySymbol = "Rs";
  String currencyCode = "PKR";
  String status = "Pending";
  String penaltyType = "%";

  DateTime issuedDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 7));

  List<ServiceRowData> serviceDatas = [];

  double subtotal = 0;
  double total = 0;

  final Map<String, String> currencyMap = {
    "PKR": "PKR",
    "USD": "\$",
    "EUR": "€",
    "GBP": "£",
    "AED": "د.إ",
    "SAR": "ر.س",
    "CAD": "\$",
    "AUD": "\$",
    "INR": "₹",
    "JPY": "¥",
    "CNY": "¥",
    "CHF": "CHF",
    "SGD": "\$",
    "MYR": "RM",
    "TRY": "₺",
  };

  @override
  void initState() {
    super.initState();
    _addServiceRow();
    _loadLastInvoiceData();

    // Focus listeners for main fields
    _paymentFocusNode.addListener(() => _updateAddButton(_paymentController.text, _paymentMethods, (v) => _showPaymentAddButton = v));
    _clientFocusNode.addListener(() => _updateAddButton(clientController.text, _clientNames, (v) => _showClientAddButton = v));
    _yourNameFocusNode.addListener(() => _updateAddButton(yourNameController.text, _yourNames, (v) => _showYourNameAddButton = v));
    _brandFocusNode.addListener(() => _updateAddButton(brandController.text, _brandNames, (v) => _showBrandAddButton = v));
    _accountFocusNode.addListener(() => _updateAddButton(accountController.text, _accounts, (v) => _showAccountAddButton = v));
    _emailFocusNode.addListener(() => _updateAddButton(emailController.text, _emails, (v) => _showEmailAddButton = v));
    _phoneFocusNode.addListener(() => _updateAddButton(phoneController.text, _phones, (v) => _showPhoneAddButton = v));
  }

  @override
  void dispose() {
    _paymentFocusNode.dispose();
    _clientFocusNode.dispose();
    _yourNameFocusNode.dispose();
    _brandFocusNode.dispose();
    _accountFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();

    _paymentController.dispose();
    clientController.dispose();
    yourNameController.dispose();
    brandController.dispose();
    accountController.dispose();
    emailController.dispose();
    phoneController.dispose();
    discountController.dispose();
    penaltyController.dispose();


    for (var row in serviceDatas) {
      row.dispose();
    }

    super.dispose();
  }

  void _updateAddButton(String text, List<String> list, void Function(bool) callback) {
    final trimmed = text.trim();
    final exists = list.any((item) => item.toLowerCase() == trimmed.toLowerCase());
    final shouldShow = trimmed.isNotEmpty && !exists;
    callback(shouldShow);
    if (mounted) setState(() {});
  }

  Future<void> _loadLastInvoiceData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _clientNames = prefs.getStringList("savedClientNames") ?? [];
      _yourNames = prefs.getStringList("savedYourNames") ?? [];
      _brandNames = prefs.getStringList("savedBrandNames") ?? [];
      _accounts = prefs.getStringList("savedAccounts") ?? [];
      _emails = prefs.getStringList("savedEmails") ?? [];
      _phones = prefs.getStringList("savedPhones") ?? [];
      _serviceNames = prefs.getStringList("savedServiceNames") ?? [];

      clientController.text = "";
      yourNameController.text = prefs.getString("yourName") ?? "";
      brandController.text = prefs.getString("brandName") ?? "";
      accountController.text = prefs.getString("accountNo") ?? "";
      emailController.text = prefs.getString("email") ?? "";
      phoneController.text = prefs.getString("phone") ?? "";
      penaltyController.text = prefs.getString("penaltyValue") ?? "0";

      final savedMethods = prefs.getStringList("savedPaymentMethods") ?? [];
      final allMethods = [...["Bank Transfer", "Cash", "EasyPaisa", "JazzCash"], ...savedMethods]
          .toSet()
          .toList()
        ..sort();

      final savedPayment = prefs.getString("paymentMethod") ?? "Bank Transfer";
      _paymentMethods = allMethods;
      _selectedPayment = allMethods.contains(savedPayment) ? savedPayment : "Bank Transfer";
      _paymentController.text = _selectedPayment;

      final savedPenaltyType = prefs.getString("penaltyType");
      if (["%", "Direct"].contains(savedPenaltyType)) {
        penaltyType = savedPenaltyType!;
      }
    });
  }

  Future<void> _addNewValue(String value, List<String> list, String prefKey) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || list.any((m) => m.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      list.add(trimmed);
      list.sort();
    });

    await prefs.setStringList(prefKey, list);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastClientName", clientController.text.trim());
    await prefs.setString("yourName", yourNameController.text.trim());
    await prefs.setString("brandName", brandController.text.trim());
    await prefs.setString("accountNo", accountController.text.trim());
    await prefs.setString("email", emailController.text.trim());
    await prefs.setString("phone", phoneController.text.trim());
    await prefs.setString("penaltyValue", penaltyController.text.trim());
    await prefs.setString("penaltyType", penaltyType);
    await prefs.setString("paymentMethod", _selectedPayment.trim());
  }

  Future<void> _pickDate(bool isIssued) async {
    final initial = isIssued ? issuedDate : dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isIssued) issuedDate = picked;
        else dueDate = picked;
      });
    }
  }

  void _addServiceRow() {
    final row = ServiceRowData();
    row.focusNode.addListener(
          () => _updateAddButton(
        row.nameController.text,
        _serviceNames,
            (v) => row.showAddButton = v,
      ),
    );
    setState(() {
      serviceDatas.add(row);
    });
  }

  void calculateTotal() {
    subtotal = serviceDatas.fold<double>(
      0,
          (sum, s) {
        final qty = double.tryParse(s.quantityController.text) ?? 0;
        final price = double.tryParse(s.priceController.text) ?? 0;
        final lineTotal = qty * price;
        s.total = lineTotal;
        return sum + lineTotal;
      },
    );

    final discount = double.tryParse(discountController.text) ?? 0;
    total = (subtotal - discount).clamp(0.0, double.infinity);

    if (mounted) setState(() {});
  }

  bool _validateForm() {
    if (clientController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Client name is required")));
      return false;
    }
    if (yourNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your name / business name is required")));
      return false;
    }
    if (serviceDatas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one service/item")));
      return false;
    }
    for (var item in serviceDatas) {
      if (item.nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All services must have a name")));
        return false;
      }
    }
    return true;
  }

  Future<void> saveInvoice() async {
    if (!_validateForm()) return;

    // Save new service names used in this invoice
    final prefs = await SharedPreferences.getInstance();
    for (var row in serviceDatas) {
      final name = row.nameController.text.trim();
      if (name.isNotEmpty && !_serviceNames.any((s) => s.toLowerCase() == name.toLowerCase())) {
        _serviceNames.add(name);
      }
    }
    await prefs.setStringList("savedServiceNames", _serviceNames);

    await _saveToPrefs();

    final invoice = Invoice(
      clientName: clientController.text.trim(),
      yourName: yourNameController.text.trim(),
      brandName: brandController.text.trim(),
      issuedDate: DateFormat("dd MMM yyyy").format(issuedDate),
      dueDate: DateFormat("dd MMM yyyy").format(dueDate),
      currencySymbol: currencySymbol,
      currencyCode: currencyCode,
      discount: double.tryParse(discountController.text) ?? 0,
      subtotal: subtotal,
      total: total,
      paymentMethod: _selectedPayment.trim(),
      accountNo: accountController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      status: status,
      penaltyType: penaltyType,
      penaltyValue: double.tryParse(penaltyController.text) ?? 0,
      notes: "",
      createdAt: DateTime.now().toString(),
    );

    final invoiceId = await repo.insertInvoice(invoice);

    final services = serviceDatas.map((s) {
      return ServiceItem(
        invoiceId: invoiceId,
        serviceName: s.nameController.text.trim(),
        quantity: int.tryParse(s.quantityController.text) ?? 0,
        price: double.tryParse(s.priceController.text) ?? 0,
        total: s.total,
      );
    }).toList();

    await repo.insertServices(services);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Invoice"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 10, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── PARTY DETAILS ────────────────────────────────────────────
            _buildCardSection(
              title: "Invoice Details",
              child: Column(
                children: [
                  _autocompleteField(
                    controller: clientController,
                    focusNode: _clientFocusNode,
                    label: "Client Name",
                    options: _clientNames,
                    showAddButton: _showClientAddButton,
                    onAdd: () => _addNewValue(clientController.text, _clientNames, "savedClientNames"),
                    capitalization: TextCapitalization.words,
                    onChanged: (v) => _updateAddButton(v, _clientNames, (b) => _showClientAddButton = b),
                  ),
                  const SizedBox(height: 16),
                  _autocompleteField(
                    controller: yourNameController,
                    focusNode: _yourNameFocusNode,
                    label: "Your Name / Business",
                    options: _yourNames,
                    showAddButton: _showYourNameAddButton,
                    onAdd: () => _addNewValue(yourNameController.text, _yourNames, "savedYourNames"),
                    capitalization: TextCapitalization.words,
                    onChanged: (v) => _updateAddButton(v, _yourNames, (b) => _showYourNameAddButton = b),
                  ),
                  const SizedBox(height: 16),
                  _autocompleteField(
                    controller: brandController,
                    focusNode: _brandFocusNode,
                    label: "Brand Name",
                    options: _brandNames,
                    showAddButton: _showBrandAddButton,
                    onAdd: () => _addNewValue(brandController.text, _brandNames, "savedBrandNames"),
                    capitalization: TextCapitalization.words,
                    onChanged: (v) => _updateAddButton(v, _brandNames, (b) => _showBrandAddButton = b),
                  ),
                  const SizedBox(height: 16),
                  _autocompleteField(
                    controller: emailController,
                    focusNode: _emailFocusNode,
                    label: "Email",
                    options: _emails,
                    showAddButton: _showEmailAddButton,
                    onAdd: () => _addNewValue(emailController.text, _emails, "savedEmails"),
                    capitalization: TextCapitalization.none,
                    keyboard: TextInputType.emailAddress,
                    onChanged: (v) => _updateAddButton(v, _emails, (b) => _showEmailAddButton = b),
                  ),
                  const SizedBox(height: 16),
                  _autocompleteField(
                    controller: phoneController,
                    focusNode: _phoneFocusNode,
                    label: "Phone",
                    options: _phones,
                    showAddButton: _showPhoneAddButton,
                    onAdd: () => _addNewValue(phoneController.text, _phones, "savedPhones"),
                    capitalization: TextCapitalization.none,
                    keyboard: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9+]*$'))],
                    onChanged: (v) => _updateAddButton(v, _phones, (b) => _showPhoneAddButton = b),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── DATES ─────────────────────────────────────────────────────
            _buildCardSection(
              title: "Invoice Dates",
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text("Issued: ${DateFormat("dd MMM yyyy").format(issuedDate)}"),
                      trailing: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      title: Text("Due: ${DateFormat("dd MMM yyyy").format(dueDate)}"),
                      trailing: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(" Services", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            ...serviceDatas.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _autocompleteField(
                        controller: data.nameController,
                        focusNode: data.focusNode,
                        label: "Service Name",
                        options: _serviceNames,
                        showAddButton: data.showAddButton,
                        onAdd: () => _addNewValue(data.nameController.text, _serviceNames, "savedServiceNames"),
                        capitalization: TextCapitalization.sentences,
                        // This is the critical fix – update visibility while typing
                        onChanged: (value) {
                          _updateAddButton(value, _serviceNames, (v) => data.showAddButton = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              data.quantityController,
                              "Quantity",
                              TextCapitalization.none,
                              keyboard: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (_) => calculateTotal(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _textField(
                              data.priceController,
                              "Unit Price",
                              TextCapitalization.none,
                              keyboard: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (_) => calculateTotal(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "$currencySymbol ${data.total.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      if (serviceDatas.length > 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                data.dispose();
                                serviceDatas.removeAt(index);
                                calculateTotal();
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _addServiceRow,
              icon: const Icon(Icons.add),
              label: const Text("Add Service"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),

            const SizedBox(height: 32),

            // Payment Information (unchanged)
            _buildCardSection(
              title: "Payment Information",
              child: Column(
                children: [
                  _autocompleteField(
                    controller: accountController,
                    focusNode: _accountFocusNode,
                    label: "Account No / IBAN",
                    options: _accounts,
                    showAddButton: _showAccountAddButton,
                    onAdd: () => _addNewValue(accountController.text, _accounts, "savedAccounts"),
                    capitalization: TextCapitalization.none,
                    onChanged: (v) => _updateAddButton(v, _accounts, (b) => _showAccountAddButton = b),
                  ),
                  const SizedBox(height: 24),

                  Text("Payment Method", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  Autocomplete<String>(
                    focusNode: _paymentFocusNode,
                    textEditingController: _paymentController,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return _paymentMethods.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      setState(() {
                        _selectedPayment = selection;
                        _paymentController.text = selection;
                        _showPaymentAddButton = false;
                      });
                      _paymentFocusNode.unfocus();
                    },
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
                          suffixIcon: _showPaymentAddButton && fieldFocusNode.hasFocus
                              ? IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            tooltip: "Add new payment method",
                            onPressed: () {
                              _addNewValue(fieldController.text, _paymentMethods, "savedPaymentMethods");
                              fieldFocusNode.unfocus();
                            },
                          )
                              : null,
                        ),
                        onChanged: (value) {
                          _selectedPayment = value.trim();
                          _updateAddButton(value, _paymentMethods, (v) => _showPaymentAddButton = v);
                        },
                        onSubmitted: (value) {
                          if (_showPaymentAddButton) {
                            _addNewValue(value, _paymentMethods, "savedPaymentMethods");
                          }
                        },
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
                        onChanged: (val) {
                          setState(() {
                            currencyCode = val!;
                            // Look up the symbol in the map using the selected key
                            currencySymbol = currencyMap[val] ?? "PKR";
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _textField(
                              penaltyController,
                              "Late Fee Penalty",
                              TextCapitalization.none,
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
                              onChanged: (String? newValue) {
                                if (newValue != null) setState(() => penaltyType = newValue!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _buildCardSection(
              title: "Totals",
              child: Column(
                children: [
                  _textField(
                    discountController,
                    "Discount / Adjustment",
                    TextCapitalization.none,
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => calculateTotal(),
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
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: saveInvoice,
                child: const Text("Save Invoice", style: TextStyle(fontSize: 17)),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Reusable autocomplete field with + add button
  Widget _autocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required List<String> options,
    required bool showAddButton,
    required VoidCallback onAdd,
    required TextCapitalization capitalization,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Autocomplete<String>(
      focusNode: focusNode,
      textEditingController: controller,
      // Show all options when field is empty/focused
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();

        if (query.isEmpty) {
          // When empty → show ALL items (or empty list if you prefer)
          return options;
        }

        // When typing → filter normally
        return options.where((option) => option.toLowerCase().contains(query));
      },
      // Optional: hide the dropdown if no options (you can remove this if you want to always show)
      displayStringForOption: (String option) => option,
      onSelected: (String selection) {
        controller.text = selection;
        focusNode.unfocus();
      },
      fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
          ) {
        return TextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          textCapitalization: capitalization,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: showAddButton && fieldFocusNode.hasFocus
                ? IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              tooltip: "Add new $label",
              onPressed: () {
                onAdd();
                fieldFocusNode.unfocus();
              },
            )
                : null,
          ),
          onChanged: (value) {
            if (onChanged != null) onChanged(value);
          },
          onSubmitted: (value) {
            if (showAddButton) onAdd();
          },
        );
      },
    );
  }

  Widget _textField(
      TextEditingController controller,
      String label,
      TextCapitalization capitalization, {
        TextInputType? keyboard,
        List<TextInputFormatter>? inputFormatters,
        ValueChanged<String>? onChanged,
      }) {
    return TextField(
      controller: controller,
      textCapitalization: capitalization,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}