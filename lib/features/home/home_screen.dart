import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/invoice_repository.dart';
import '../../core/models/invoice_model.dart';
import '../../core/theme/theme_provider.dart';
import '../invoice_form/invoice_form_screen.dart';
import '../invoice_view/invoice_preview_screen.dart'; // Assuming this is the correct import name
import '../directories/client_directory_screen.dart';
import '../directories/service_directory_screen.dart';
import 'widgets/financial_summary_dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final repo = InvoiceRepository();
  List<Invoice> allInvoices = [];
  final searchController = TextEditingController();

  List<String> displayOrder = [];
  Map<String, List<Invoice>> grouped = {};

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
    if (query.trim().isEmpty) {
      allInvoices = await repo.getAllInvoices();
    } else {
      allInvoices = await repo.searchInvoices(query.trim());
    }

    _calculateStats();
    await _groupAndSort();
  }

  void _calculateStats() {
    double received = 0.0;
    double unpaid = 0.0;
    int overdue = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputFormat = DateFormat("d MMM yyyy");

    for (var inv in allInvoices) {
      received += inv.paidAmount;
      unpaid += (inv.total - inv.paidAmount);

      if (inv.status.toLowerCase() != 'paid') {
        try {
          final dueDate = inputFormat.parse(inv.dueDate);
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

  Future<void> _groupAndSort() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedClients = prefs.getStringList('savedClientNames') ?? [];

    // Group current invoices by client name (trimmed for consistency)
    grouped = {};
    for (var inv in allInvoices) {
      final client = inv.clientName.trim();
      grouped.putIfAbsent(client, () => []).add(inv);
    }

    // Clients that currently have invoices
    final activeClients = grouped.keys.toSet();

    // Keep saved order for clients that still exist
    displayOrder = savedClients.where((c) => activeClients.contains(c)).toList();

    // Add any newly appeared clients at the end
    final newClients = activeClients.difference(savedClients.toSet()).toList();
    displayOrder.addAll(newClients);

    // Update saved list (add new ones, keep old ones even if currently empty)
    final updatedSaved = [...savedClients, ...newClients].toSet().toList();
    await prefs.setStringList('savedClientNames', updatedSaved);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showPaymentDialog(Invoice invoice) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Payment for Invoice #${invoice.id}"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Current: ${invoice.paidAmount.toStringAsFixed(2)} / ${invoice.total.toStringAsFixed(2)} ${invoice.currencySymbol}",
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
                  prefixText: "${invoice.currencySymbol} ",
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
        try {
          await repo.recordPayment(invoice.id!, amount);
          await loadData(query: searchController.text);
          if (mounted) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(
            //       amount >= 0
            //           ? "Added ${invoice.currencySymbol}${amount.toStringAsFixed(2)}"
            //           : "Deducted ${invoice.currencySymbol}${(-amount).toStringAsFixed(2)}",
            //     ),
            //   ),
            // );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e")),
            );
          }
        }
      }
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Database restored. Please restart the app to see your data."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTile(Invoice invoice) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isPaid = invoice.status.toLowerCase() == 'paid';
    final isPartial = invoice.status.toLowerCase() == 'partially_paid';
    final isPending = !isPaid && !isPartial;
    DateFormat inputFormat = DateFormat("d MMM yyyy");

    DateTime dueDate = inputFormat.parse(invoice.dueDate);

    final isDue = dueDate.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Hero(
        tag: "invoice-${invoice.id}",
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
              final services = await repo.getServicesByInvoice(invoice.id!);
              final int clientInvoiceSequence = await repo.getClientInvoiceSequence(invoice.id!, invoice.clientName);

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoiceViewScreen(
                    invoice: invoice,
                    services: services,
                    clientInvoiceSequence: clientInvoiceSequence,
                    callBack: () async {
                      print("Deleted");
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
                      ? colorScheme.primary.withOpacity(0.15)
                      : isPartial
                      ? colorScheme.tertiary.withOpacity(0.15)
                      : isDue
                      ? colorScheme.error.withOpacity(0.12)
                      :colorScheme.primary.withOpacity(0.15),
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
                "Invoice #${invoice.id}",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "${invoice.currencySymbol} ${invoice.total.toStringAsFixed(0)} • ${invoice.status.toUpperCase()}",
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
    final totalAmount = invoices.fold<double>(0, (sum, inv) => sum + inv.total);
    final pendingAmount = invoices
        .where((inv) => inv.status.toLowerCase() != 'paid')
        .fold<double>(0, (sum, inv) => sum + (inv.total - inv.paidAmount));
    final pendingCount = invoices.where((inv) => inv.status.toLowerCase() != 'paid').length;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: ValueKey(clientName), // Required for ReorderableListView
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.15),

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
                "${invoices.isNotEmpty ? invoices.first.currencySymbol : ''} ${totalAmount.toStringAsFixed(0)}",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              if (pendingAmount > 0)
                Text(
                  "Due: ${invoices.isNotEmpty ? invoices.first.currencySymbol : ''} ${pendingAmount.toStringAsFixed(0)}",
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
              final repository = InvoiceRepository();

              switch (value) {
                case 'theme':
                  ref.read(themeProvider.notifier).toggleTheme();
                  break;

                case 'export':
                  final result = await repository.exportDatabase();
                  _showSnackbar(context, result ?? "Export task finished");
                  break;

                case 'import':
                  final result = await repository.importDatabase();
                  // We show a dialog because the app usually needs a restart after DB overwrite
                  if (result != null && result.contains("restored")) {
                    _showRestartDialog(context);
                  } else {
                    _showSnackbar(context, result ?? "Import task finished");
                  }
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
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.unarchive, size: 20),
                    SizedBox(width: 10),
                    Text("Export Backup"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.archive, size: 20),
                    SizedBox(width: 10),
                    Text("Import Backup"),
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
          );
          await loadData(query: searchController.text);
        },
        icon: const Icon(Icons.add),
        label: const Text("New Invoice"),
      ),
    );
  }
}