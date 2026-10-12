import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../backend/supabase/supabase_service.dart';
import 'widgets/service_row_data.dart';
import 'widgets/project_client_section.dart';
import 'widgets/project_dates_section.dart';
import 'widgets/service_row_item.dart';
import 'widgets/payment_info_section.dart';
import 'widgets/invoice_totals_section.dart';
import 'widgets/invoice_style_section.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final supabaseService = SupabaseService();
  bool isSaving = false;

  final clientController = TextEditingController();
  final yourNameController = TextEditingController();
  final brandController = TextEditingController();
  final accountController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final discountController = TextEditingController(text: "0");
  final penaltyController = TextEditingController(text: "0");

  final _paymentController = TextEditingController();
  final _paymentFocusNode = FocusNode();
  List<String> _paymentMethods = ["Bank Transfer", "Cash", "EasyPaisa", "JazzCash"];
  String _selectedPayment = "Bank Transfer";
  bool _showPaymentAddButton = false;

  List<String> _clientNames = [];
  List<String> _yourNames = [];
  List<String> _brandNames = [];
  List<String> _accounts = [];
  List<String> _emails = [];
  List<String> _phones = [];
  List<String> _serviceNames = [];

  bool _showClientAddButton = false;
  bool _showYourNameAddButton = false;
  bool _showBrandAddButton = false;
  bool _showAccountAddButton = false;
  bool _showEmailAddButton = false;
  bool _showPhoneAddButton = false;

  final _clientFocusNode = FocusNode();
  final _yourNameFocusNode = FocusNode();
  final _brandFocusNode = FocusNode();
  final _accountFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  String currencySymbol = "\$";
  String currencyCode = "USD";
  String penaltyType = "%";
  String templateStyle = "classic";
  String accentColor = "default";

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
    callback(trimmed.isNotEmpty && !exists);
    if (mounted) setState(() {});
  }

  Future<void> _loadAutocompleteLists() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _clientNames = prefs.getStringList("savedClientNames") ?? [];
        _yourNames = prefs.getStringList("savedYourNames") ?? [];
        _brandNames = prefs.getStringList("savedBrandNames") ?? [];
        _accounts = prefs.getStringList("savedAccounts") ?? [];
        _emails = prefs.getStringList("savedEmails") ?? [];
        _phones = prefs.getStringList("savedPhones") ?? [];
        _serviceNames = prefs.getStringList("savedServiceNames") ?? [];

        final savedMethods = prefs.getStringList("savedPaymentMethods") ?? [];
        _paymentMethods = [...["Bank Transfer", "Cash", "EasyPaisa", "JazzCash"], ...savedMethods].toSet().toList()..sort();
      });
    }
  }

  Future<void> _loadLastInvoiceData() async {
    await _loadAutocompleteLists();
    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        yourNameController.text = prefs.getString("yourName") ?? "";
        brandController.text = prefs.getString("brandName") ?? "";
        accountController.text = prefs.getString("accountNo") ?? "";
        emailController.text = prefs.getString("email") ?? "";
        phoneController.text = prefs.getString("phone") ?? "";
        penaltyController.text = prefs.getString("penaltyValue") ?? "0";

        final savedPayment = prefs.getString("paymentMethod") ?? "Bank Transfer";
        _selectedPayment = _paymentMethods.contains(savedPayment) ? savedPayment : "Bank Transfer";
        _paymentController.text = _selectedPayment;

        final savedPenaltyType = prefs.getString("penaltyType");
        if (["%", "Direct"].contains(savedPenaltyType)) {
          penaltyType = savedPenaltyType!;
        }
      });
    }
  }

  Future<void> _addNewValue(String value, List<String> list, String prefKey) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || list.any((m) => m.toLowerCase() == trimmed.toLowerCase())) return;

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
        if (isIssued) {
          issuedDate = picked;
        } else {
          dueDate = picked;
        }
      });
    }
  }

  void _addServiceRow() {
    final row = ServiceRowData();
    row.focusNode.addListener(() => _updateAddButton(row.nameController.text, _serviceNames, (v) => row.showAddButton = v));
    setState(() => serviceDatas.add(row));
  }

  void calculateTotal() {
    subtotal = serviceDatas.fold<double>(0, (sum, s) {
      final qty = double.tryParse(s.quantityController.text) ?? 0;
      final price = double.tryParse(s.priceController.text) ?? 0;
      final lineTotal = qty * price;
      s.total = lineTotal;
      return sum + lineTotal;
    });

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

    setState(() => isSaving = true);

    try {
      final clientName = clientController.text.trim();
      if (clientName.isNotEmpty && !_clientNames.any((c) => c.toLowerCase() == clientName.toLowerCase())) {
        await _addNewValue(clientName, _clientNames, "savedClientNames");
      }

      final prefs = await SharedPreferences.getInstance();
      for (var row in serviceDatas) {
        final name = row.nameController.text.trim();
        if (name.isNotEmpty && !_serviceNames.any((s) => s.toLowerCase() == name.toLowerCase())) {
          _serviceNames.add(name);
        }
      }
      await prefs.setStringList("savedServiceNames", _serviceNames);
      await _saveToPrefs();

      final servicesList = serviceDatas.map((s) => {
        'name': s.nameController.text.trim(),
        'quantity': int.tryParse(s.quantityController.text) ?? 0,
        'unit_price': double.tryParse(s.priceController.text) ?? 0.0,
        'total': s.total,
      }).toList();

      final projectData = {
        'client_name': clientController.text.trim(),
        'brand_name': brandController.text.trim(),
        'date_from': DateFormat("yyyy-MM-dd").format(issuedDate),
        'date_to': DateFormat("yyyy-MM-dd").format(dueDate),
        'total_no_of_tasks': 0,
        'total_payment': total,
        'paid_amount': 0.0,
        'services': servicesList,
        'shared_with': [],
      };

      await supabaseService.createProject(projectData);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating project: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(title: const Text("Create Project"), elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 10, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProjectClientSection(
              clientController: clientController,
              clientFocusNode: _clientFocusNode,
              clientNames: _clientNames,
              showClientAddButton: _showClientAddButton,
              onAddClient: () => _addNewValue(clientController.text, _clientNames, "savedClientNames"),
              onClientChanged: (v) => _updateAddButton(v, _clientNames, (b) => _showClientAddButton = b),
              onClientSelected: (_) {},
              yourNameController: yourNameController,
              yourNameFocusNode: _yourNameFocusNode,
              yourNames: _yourNames,
              showYourNameAddButton: _showYourNameAddButton,
              onAddYourName: () => _addNewValue(yourNameController.text, _yourNames, "savedYourNames"),
              onYourNameChanged: (v) => _updateAddButton(v, _yourNames, (b) => _showYourNameAddButton = b),
              brandController: brandController,
              brandFocusNode: _brandFocusNode,
              brandNames: _brandNames,
              showBrandAddButton: _showBrandAddButton,
              onAddBrand: () => _addNewValue(brandController.text, _brandNames, "savedBrandNames"),
              onBrandChanged: (v) => _updateAddButton(v, _brandNames, (b) => _showBrandAddButton = b),
              emailController: emailController,
              emailFocusNode: _emailFocusNode,
              emails: _emails,
              showEmailAddButton: _showEmailAddButton,
              onAddEmail: () => _addNewValue(emailController.text, _emails, "savedEmails"),
              onEmailChanged: (v) => _updateAddButton(v, _emails, (b) => _showEmailAddButton = b),
              phoneController: phoneController,
              phoneFocusNode: _phoneFocusNode,
              phones: _phones,
              showPhoneAddButton: _showPhoneAddButton,
              onAddPhone: () => _addNewValue(phoneController.text, _phones, "savedPhones"),
              onPhoneChanged: (v) => _updateAddButton(v, _phones, (b) => _showPhoneAddButton = b),
              onClientDirectoryReturn: _loadAutocompleteLists,
            ),
            const SizedBox(height: 32),

            ProjectDatesSection(
              issuedDate: issuedDate,
              dueDate: dueDate,
              onPickIssuedDate: () => _pickDate(true),
              onPickDueDate: () => _pickDate(false),
            ),
            const SizedBox(height: 32),

            Text(" Services Included", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            ...serviceDatas.asMap().entries.map((entry) {
              return ServiceRowItem(
                data: entry.value,
                index: entry.key,
                canDelete: serviceDatas.length > 1,
                serviceNames: _serviceNames,
                currencySymbol: currencySymbol,
                onAddServiceValue: () => _addNewValue(entry.value.nameController.text, _serviceNames, "savedServiceNames"),
                onDeleteRow: () {
                  setState(() {
                    entry.value.dispose();
                    serviceDatas.removeAt(entry.key);
                    calculateTotal();
                  });
                },
                onCalculateTotal: calculateTotal,
                onServiceDirectoryReturn: _loadAutocompleteLists,
              );
            }),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addServiceRow,
              icon: const Icon(Icons.add),
              label: const Text("Add Service"),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
            const SizedBox(height: 32),

            PaymentInfoSection(
              accountController: accountController,
              accountFocusNode: _accountFocusNode,
              accounts: _accounts,
              showAccountAddButton: _showAccountAddButton,
              onAddAccount: () => _addNewValue(accountController.text, _accounts, "savedAccounts"),
              onAccountChanged: (v) => _updateAddButton(v, _accounts, (b) => _showAccountAddButton = b),
              paymentController: _paymentController,
              paymentFocusNode: _paymentFocusNode,
              paymentMethods: _paymentMethods,
              showPaymentAddButton: _showPaymentAddButton,
              onAddPaymentMethod: () => _addNewValue(_paymentController.text, _paymentMethods, "savedPaymentMethods"),
              onPaymentMethodSelected: (sel) {
                setState(() {
                  _selectedPayment = sel;
                  _paymentController.text = sel;
                  _showPaymentAddButton = false;
                });
                _paymentFocusNode.unfocus();
              },
              currencyCode: currencyCode,
              onCurrencyChanged: (val) {
                if (val != null) {
                  setState(() {
                    currencyCode = val;
                    currencySymbol = currencyMap[val] ?? "PKR";
                  });
                }
              },
              penaltyController: penaltyController,
              penaltyType: penaltyType,
              onPenaltyTypeChanged: (val) {
                if (val != null) setState(() => penaltyType = val);
              },
            ),
            const SizedBox(height: 32),

            InvoiceTotalsSection(
              discountController: discountController,
              currencySymbol: currencySymbol,
              subtotal: subtotal,
              total: total,
              onCalculateTotal: calculateTotal,
            ),
            const SizedBox(height: 32),

            InvoiceStyleSection(
              templateStyle: templateStyle,
              onSelectTemplate: (style) => setState(() => templateStyle = style),
              accentColor: accentColor,
              onSelectAccentColor: (color) => setState(() => accentColor = color),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isSaving ? null : saveInvoice,
                child: isSaving ? const CircularProgressIndicator() : const Text("Save Project", style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
