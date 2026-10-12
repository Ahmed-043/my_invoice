import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme_provider.dart';
import '../invoice_form/invoice_form_screen.dart';
import '../invoice_view/invoice_preview_screen.dart';
import '../directories/client_directory_screen.dart';
import '../directories/service_directory_screen.dart';
import 'widgets/financial_summary_dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> allInvoices = [];
  Map<int, List<Map<String, dynamic>>> invoiceServicesMap = {};
  final searchController = TextEditingController();

  List<String> displayOrder = [];
  Map<String, List<Map<String, dynamic>>> grouped = {};

  double totalReceived = 0.0;
  double totalReceivables = 0.0;
  int overdueCount = 0;
  double collectionProgress = 0.0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData({String query = ''}) async {
    _calculateStats();
    await _groupAndSort(query: query);
  }

  void _calculateStats() {
    double received = 0.0;
    double unpaid = 0.0;
    int overdue = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputFormat = DateFormat("d MMM yyyy");

    for (var inv in allInvoices) {
      final paidAmount = (inv['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final total = (inv['total'] as num?)?.toDouble() ?? 0.0;
      final status = (inv['status'] as String? ?? 'pending').toLowerCase();
      final dueDateStr = inv['dueDate'] as String? ?? '';

      received += paidAmount;
      unpaid += (total - paidAmount);

      if (status != 'paid') {
        try {
          final dueDate = inputFormat.parse(dueDateStr);
          final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          if (dueDay.isBefore(today)) {
            overdue++;
          }
        } catch (e) {
          // ignore parsing error
        }
      }
    }

    totalReceived = received;
    totalReceivables = unpaid;
    overdueCount = overdue;

    final totalVolume = totalReceived + totalReceivables;
    collectionProgress = totalVolume > 0 ? (totalReceived / totalVolume) : 0.0;
  }

  Future<void> _groupAndSort({String query = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedClients = prefs.getStringList('savedClientNames') ?? [];

    List<Map<String, dynamic>> filteredInvoices = allInvoices;
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filteredInvoices = allInvoices.where((inv) {
        final idStr = inv['id'].toString();
        final clientName = (inv['clientName'] as String? ?? '').toLowerCase();
        final yourName = (inv['yourName'] as String? ?? '').toLowerCase();
        final brandName = (inv['brandName'] as String? ?? '').toLowerCase();

        return idStr == q ||
            clientName.contains(q) ||
            yourName.contains(q) ||
            brandName.contains(q);
      }).toList();
    }

    grouped = {};
    for (var inv in filteredInvoices) {
      final client = (inv['clientName'] as String? ?? '').trim();
      grouped.putIfAbsent(client, () => []).add(inv);
    }

    final activeClients = grouped.keys.toSet();
    displayOrder = savedClients.where((c) => activeClients.contains(c)).toList();

    final newClients = activeClients.difference(savedClients.toSet()).toList();
    displayOrder.addAll(newClients);

    final updatedSaved = [...savedClients, ...newClients].toSet().toList();
    await prefs.setStringList('savedClientNames', updatedSaved);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showPaymentDialog(Map<String, dynamic> invoice) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final id = invoice['id'];
    final paidAmount = (invoice['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final total = (invoice['total'] as num?)?.toDouble() ?? 0.0;
    final currencySymbol = invoice['currencySymbol'] as String? ?? 'Rs';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Payment for Invoice #$id"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Current: ${paidAmount.toStringAsFixed(2)} / ${total.toStringAsFixed(2)} $currencySymbol",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixText: "$currencySymbol ",
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter an amount";
                  if (double.tryParse(value) == null) return "Invalid number";
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text(
                "Tip: Use negative value (e.g. -1500) to deduct/refund",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text("Apply Payment"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final amountText = amountController.text.trim();
      final amount = double.tryParse(amountText);

      if (amount != null) {
        final index = allInvoices.indexWhere((i) => i['id'] == id);
        if (index != -1) {
          final current = allInvoices[index];
          final currentPaid = (current['paidAmount'] as num?)?.toDouble() ?? 0.0;
          final currentTotal = (current['total'] as num?)?.toDouble() ?? 0.0;

          double newPaid = (currentPaid + amount).clamp(0.0, currentTotal);
          String newStatus = newPaid >= currentTotal
              ? 'paid'
              : (newPaid > 0 ? 'partially_paid' : 'pending');

          allInvoices[index]['paidAmount'] = newPaid;
          allInvoices[index]['status'] = newStatus;

          await loadData(query: searchController.text);
        }
      }
    }
  }

  int _getClientInvoiceSequence(Map<String, dynamic> invoice) {
    final clientName = (invoice['clientName'] as String? ?? '').trim().toLowerCase();
    final id = invoice['id'];

    final clientInvoices = allInvoices
        .where((i) => (i['clientName'] as String? ?? '').trim().toLowerCase() == clientName)
        .toList();

    final index = clientInvoices.indexWhere((i) => i['id'] == id);
    return index != -1 ? index + 1 : 1;
  }

  Widget _buildInvoiceTile(Map<String, dynamic> invoice) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final id = invoice['id'];
    final status = (invoice['status'] as String? ?? 'pending').toLowerCase();
    final currencySymbol = invoice['currencySymbol'] as String? ?? 'Rs';
    final total = (invoice['total'] as num?)?.toDouble() ?? 0.0;
    final dueDateStr = invoice['dueDate'] as String? ?? '';

    final isPaid = status == 'paid';
    final isPartial = status == 'partially_paid';
    final isPending = !isPaid && !isPartial;
    DateFormat inputFormat = DateFormat("d MMM yyyy");

    DateTime dueDate = DateTime.now();
    try {
      dueDate = inputFormat.parse(dueDateStr);
    } catch (_) {}

    final isDue = dueDate.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Hero(
        tag: "invoice-$id",
        child: Card(
          elevation: isPending ? 2 : 1,
          shadowColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isPending
              ? colorScheme.primaryContainer
              : isPartial
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final services = invoiceServicesMap[id] ?? [];
              final int clientInvoiceSequence = _getClientInvoiceSequence(invoice);

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoiceViewScreen(
                    invoice: invoice,
                    services: services,
                    clientInvoiceSequence: clientInvoiceSequence,
                    callBack: () async {
                      await loadData(query: searchController.text);
                    },
                  ),
                ),
              );
            },
            onLongPress: () => _showPaymentDialog(invoice),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPaid
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : isPartial
                      ? colorScheme.tertiary.withValues(alpha: 0.15)
                      : isDue
                      ? colorScheme.error.withValues(alpha: 0.12)
                      : colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle_rounded
                      : isPartial
                      ? Icons.hourglass_bottom_rounded
                      : Icons.schedule_rounded,
                  color: isPaid
                      ? colorScheme.primary
                      : isPartial
                      ? isDue
                      ? colorScheme.error
                      : colorScheme.tertiary
                      : isDue
                      ? colorScheme.error
                      : colorScheme.primary,
                  size: 28,
                ),
              ),
              title: Text(
                "Invoice #$id",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "$currencySymbol ${total.toStringAsFixed(0)} • ${status.toUpperCase()}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isPaid
                      ? colorScheme.primary
                      : isPartial
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.payment_rounded, color: colorScheme.primary),
                onPressed: () => _showPaymentDialog(invoice),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientExpansionTile(String clientName) {
    final invoices = grouped[clientName]!;
    final totalAmount = invoices.fold<double>(0, (sum, inv) => sum + ((inv['total'] as num?)?.toDouble() ?? 0.0));
    final pendingAmount = invoices
        .where((inv) => (inv['status'] as String? ?? '').toLowerCase() != 'paid')
        .fold<double>(0, (sum, inv) {
      final total = (inv['total'] as num?)?.toDouble() ?? 0.0;
      final paid = (inv['paidAmount'] as num?)?.toDouble() ?? 0.0;
      return sum + (total - paid);
    });
    final pendingCount = invoices.where((inv) => (inv['status'] as String? ?? '').toLowerCase() != 'paid').length;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencySymbol = invoices.isNotEmpty ? (invoices.first['currencySymbol'] as String? ?? 'Rs') : 'Rs';

    return Card(
      key: ValueKey(clientName),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          childrenPadding: const EdgeInsets.only(bottom: 5),
          backgroundColor: colorScheme.surfaceBright,
          collapsedBackgroundColor: colorScheme.surfaceContainerHigh,
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            clientName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                "${invoices.length} invoice${invoices.length == 1 ? '' : 's'}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$pendingCount pending",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$currencySymbol ${totalAmount.toStringAsFixed(0)}",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              if (pendingAmount > 0)
                Text(
                  "Due: $currencySymbol ${pendingAmount.toStringAsFixed(0)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          children: invoices.map(_buildInvoiceTile).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoixa"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'theme':
                  ref.read(themeProvider.notifier).toggleTheme();
                  break;

                case 'clients':
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientDirectoryScreen()),
                  );
                  await loadData(query: searchController.text);
                  break;

                case 'services':
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServiceDirectoryScreen()),
                  );
                  await loadData(query: searchController.text);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6, size: 20),
                    SizedBox(width: 10),
                    Text("Toggle Theme"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clients',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 20),
                    SizedBox(width: 10),
                    Text("Client Directory"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'services',
                child: Row(
                  children: [
                    Icon(Icons.design_services_outlined, size: 20),
                    SizedBox(width: 10),
                    Text("Service Directory"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          FinancialSummaryDashboard(
            hasInvoices: allInvoices.isNotEmpty,
            collectionProgress: collectionProgress,
            totalReceived: totalReceived,
            totalReceivables: totalReceivables,
            overdueCount: overdueCount,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (value) => loadData(query: value),
              decoration: InputDecoration(
                hintText: 'Search by ID or client name...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: allInvoices.isEmpty
                ? const Center(
                    child: Text(
                      "No invoices yet",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  )
                : displayOrder.isEmpty
                    ? const Center(child: Text("Loading clients..."))
                    : ReorderableListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        onReorder: (oldIndex, newIndex) async {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = displayOrder.removeAt(oldIndex);
                            displayOrder.insert(newIndex, item);
                          });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setStringList('savedClientNames', displayOrder);
                        },
                        children: displayOrder.map((client) {
                          return _buildClientExpansionTile(client);
                        }).toList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
          );
          if (result != null) {
            final invoice = result['invoice'] as Map<String, dynamic>?;
            final services = result['services'] as List<Map<String, dynamic>>?;
            if (invoice != null && services != null) {
              final id = invoice['id'] as int;
              setState(() {
                allInvoices.insert(0, invoice);
                invoiceServicesMap[id] = services;
              });
            }
          }
          await loadData(query: searchController.text);
        },
        icon: const Icon(Icons.add),
        label: const Text("New Invoice"),
      ),
    );
  }
}
