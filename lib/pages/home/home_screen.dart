import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme_provider.dart';
import '../../backend/supabase/supabase_service.dart';
import '../auth/auth_screen.dart';
import '../invoice_form/invoice_form_screen.dart';
import '../client_directory/client_directory_screen.dart';
import '../service_directory/service_directory_screen.dart';
import 'widgets/financial_summary_dashboard.dart';
import 'widgets/client_expansion_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final supabaseService = SupabaseService();
  bool isLoading = true;

  List<Map<String, dynamic>> allInvoices = [];
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
    try {
      final projects = await supabaseService.getProjects();
      allInvoices = projects.map((p) {
        final totalPay = (p['total_payment'] as num?)?.toDouble() ?? 0.0;
        final paid = (p['paid_amount'] as num?)?.toDouble() ?? 0.0;
        String status = 'pending';
        if (paid >= totalPay && totalPay > 0) {
          status = 'paid';
        } else if (paid > 0) {
          status = 'partially_paid';
        }

        List<Map<String, dynamic>> serviceList = [];
        if (p['services'] != null && p['services'] is List) {
          serviceList = List<Map<String, dynamic>>.from(p['services']);
        }

        return {
          'id': p['id'],
          'clientName': p['client_name'] ?? '',
          'yourName': p['brand_name'] ?? '',
          'brandName': p['brand_name'] ?? '',
          'issuedDate': p['date_from'] ?? '',
          'dueDate': p['date_to'] ?? '',
          'currencySymbol': '\$',
          'currencyCode': 'USD',
          'discount': 0.0,
          'subtotal': totalPay,
          'total': totalPay,
          'paidAmount': paid,
          'paymentMethod': 'Bank Transfer',
          'accountNo': '',
          'email': '',
          'phone': '',
          'status': status,
          'penaltyType': '%',
          'penaltyValue': 0.0,
          'notes': '',
          'createdAt': p['created_at'] ?? '',
          'templateStyle': 'classic',
          'accentColor': 'default',
          'rawServices': serviceList,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching projects: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }

    _calculateStats();
    await _groupAndSort(query: query);
  }

  void _calculateStats() {
    double received = 0.0;
    double unpaid = 0.0;
    int overdue = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputFormat = DateFormat("yyyy-MM-dd");

    for (var inv in allInvoices) {
      final paidAmount = (inv['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final total = (inv['total'] as num?)?.toDouble() ?? 0.0;
      final status = (inv['status'] as String? ?? 'pending').toLowerCase();
      final dueDateStr = inv['dueDate'] as String? ?? '';

      received += paidAmount;
      unpaid += (total - paidAmount);

      if (status != 'paid' && dueDateStr.isNotEmpty) {
        try {
          final dueDate = inputFormat.parse(dueDateStr);
          final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          if (dueDay.isBefore(today)) {
            overdue++;
          }
        } catch (_) {}
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
        final idStr = inv['id'].toString().toLowerCase();
        final clientName = (inv['clientName'] as String? ?? '').toLowerCase();
        final brandName = (inv['brandName'] as String? ?? '').toLowerCase();

        return idStr.contains(q) || clientName.contains(q) || brandName.contains(q);
      }).toList();
    }

    grouped = {};
    for (var inv in filteredInvoices) {
      final client = (inv['clientName'] as String? ?? '').trim();
      if (client.isNotEmpty) {
        grouped.putIfAbsent(client, () => []).add(inv);
      }
    }

    final activeClients = grouped.keys.toSet();
    displayOrder = savedClients.where((c) => activeClients.contains(c)).toList();

    final newClients = activeClients.difference(savedClients.toSet()).toList();
    displayOrder.addAll(newClients);

    final updatedSaved = [...savedClients, ...newClients].toSet().toList();
    await prefs.setStringList('savedClientNames', updatedSaved);

    if (mounted) setState(() {});
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

                case 'seed_data':
                  try {
                    setState(() => isLoading = true);
                    await supabaseService.seedDummyData();
                    await loadData(query: searchController.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Inserted dummy test data across all tables!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error seeding data: $e"), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => isLoading = false);
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

                case 'logout':
                  await supabaseService.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6, size: 20),
                    SizedBox(width: 10),
                    Text("Toggle Theme"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'seed_data',
                child: Row(
                  children: [
                    Icon(Icons.data_saver_on_outlined, size: 20, color: Colors.blue),
                    SizedBox(width: 10),
                    Text("Seed Test Data"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clients',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 20),
                    SizedBox(width: 10),
                    Text("Client Directory"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'services',
                child: Row(
                  children: [
                    Icon(Icons.design_services_outlined, size: 20),
                    SizedBox(width: 10),
                    Text("Service Directory"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Sign Out", style: TextStyle(color: Colors.red)),
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : allInvoices.isEmpty
                    ? const Center(
                        child: Text(
                          "No projects yet",
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
                              return ClientExpansionTile(
                                key: ValueKey(client),
                                clientName: client,
                                invoices: grouped[client] ?? [],
                                getSequence: _getClientInvoiceSequence,
                                onRefreshNeeded: () => loadData(query: searchController.text),
                                supabaseService: supabaseService,
                              );
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
        label: const Text("New Project"),
      ),
    );
  }
}
