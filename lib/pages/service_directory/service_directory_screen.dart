import 'package:flutter/material.dart';
import '../../backend/supabase/supabase_service.dart';
import 'widgets/service_tile.dart';
import 'widgets/service_form_dialog.dart';

class ServiceDirectoryScreen extends StatefulWidget {
  final bool selectionMode;

  const ServiceDirectoryScreen({super.key, this.selectionMode = false});

  @override
  State<ServiceDirectoryScreen> createState() => _ServiceDirectoryScreenState();
}

class _ServiceDirectoryScreenState extends State<ServiceDirectoryScreen> {
  final supabaseService = SupabaseService();
  bool isLoading = true;

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadServices({String query = ''}) async {
    try {
      final list = await supabaseService.getPredefinedServices();
      services = list.map((s) {
        return {
          'id': s['id'],
          'name': s['name'] ?? '',
          'description': s['description'] ?? '',
          'defaultPrice': (s['default_price'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error loading services: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }

    _filterServices(query: query);
  }

  void _filterServices({String query = ''}) {
    if (query.trim().isEmpty) {
      filteredServices = List.from(services);
    } else {
      final q = query.trim().toLowerCase();
      filteredServices = services.where((s) {
        final name = (s['name'] as String? ?? '').toLowerCase();
        final description = (s['description'] as String? ?? '').toLowerCase();
        return name.contains(q) || description.contains(q);
      }).toList();
    }
    if (mounted) setState(() {});
  }

  void _openServiceDialog({Map<String, dynamic>? service}) {
    showAddEditServiceDialog(
      context: context,
      supabaseService: supabaseService,
      service: service,
      onSaved: () => loadServices(query: searchController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? "Select Service" : "Service Directory"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => _filterServices(query: value),
              decoration: InputDecoration(
                hintText: "Search services...",
                prefixIcon: const Icon(Icons.search),
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
                : filteredServices.isEmpty
                    ? Center(
                        child: Text(
                          searchController.text.isEmpty ? "No services saved yet." : "No matching services found.",
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredServices.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          return ServiceTile(
                            service: service,
                            selectionMode: widget.selectionMode,
                            onEdit: () => _openServiceDialog(service: service),
                            onDelete: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text("Delete Service"),
                                  content: Text("Are you sure you want to delete ${service['name']}?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        try {
                                          await supabaseService.deletePredefinedService(service['id'].toString());
                                          if (mounted) {
                                            Navigator.pop(dialogContext);
                                            await loadServices(query: searchController.text);
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Delete error: $e"), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onTap: () {
                              if (widget.selectionMode) {
                                Navigator.pop(context, service);
                              } else {
                                _openServiceDialog(service: service);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openServiceDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Service"),
      ),
    );
  }
}
