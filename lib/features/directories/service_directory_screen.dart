import 'package:flutter/material.dart';

class ServiceDirectoryScreen extends StatefulWidget {
  /// When true, tapping a service will `pop()` the selected service map instead of opening edit.
  /// Editing remains available via the edit icon.
  final bool selectionMode;

  const ServiceDirectoryScreen({super.key, this.selectionMode = false});

  @override
  State<ServiceDirectoryScreen> createState() => _ServiceDirectoryScreenState();
}

class _ServiceDirectoryScreenState extends State<ServiceDirectoryScreen> {
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

  void loadServices({String query = ''}) {
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

  void _showAddEditServiceDialog({Map<String, dynamic>? service}) {
    final nameController = TextEditingController(text: service?['name'] as String? ?? '');
    final descriptionController = TextEditingController(text: service?['description'] as String? ?? '');
    final priceController = TextEditingController(
      text: service != null ? ((service['defaultPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service == null ? "Add Service/Item" : "Edit Service/Item"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Service/Item Name *"),
                  validator: (v) => v == null || v.trim().isEmpty ? "Name is required" : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Default Unit Price", prefixText: "Rs "),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Price is required";
                    if (double.tryParse(v) == null) return "Enter a valid number";
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newService = {
                  'id': service?['id'] ?? DateTime.now().millisecondsSinceEpoch,
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'defaultPrice': double.parse(priceController.text.trim()),
                };

                if (service == null) {
                  services.add(newService);
                } else {
                  final index = services.indexWhere((s) => s['id'] == service['id']);
                  if (index != -1) {
                    services[index] = newService;
                  }
                }

                Navigator.pop(context);
                loadServices(query: searchController.text);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              onChanged: (value) => loadServices(query: value),
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
            child: filteredServices.isEmpty
                ? Center(
                    child: Text(
                      searchController.text.isEmpty
                          ? "No services saved yet."
                          : "No matching services found.",
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredServices.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      final name = service['name'] as String? ?? '';
                      final description = service['description'] as String? ?? '';
                      final defaultPrice = (service['defaultPrice'] as num?)?.toDouble() ?? 0.0;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
                            foregroundColor: colorScheme.secondary,
                            child: const Icon(Icons.design_services_outlined),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: description.isNotEmpty
                              ? Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Rs ${defaultPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showAddEditServiceDialog(service: service),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text("Delete Service"),
                                      content: Text("Are you sure you want to delete $name?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            services.removeWhere((s) => s['id'] == service['id']);
                                            Navigator.pop(dialogContext);
                                            loadServices(query: searchController.text);
                                          },
                                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            if (widget.selectionMode) {
                              Navigator.pop(context, service);
                            } else {
                              _showAddEditServiceDialog(service: service);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditServiceDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Service"),
      ),
    );
  }
}
