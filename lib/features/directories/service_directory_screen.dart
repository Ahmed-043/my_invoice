import 'package:flutter/material.dart';
import '../../core/database/invoice_repository.dart';
import '../../core/models/predefined_service_model.dart';

class ServiceDirectoryScreen extends StatefulWidget {
  /// When true, tapping a service will `pop()` the selected [PredefinedService] instead of opening edit.
  /// Editing remains available via the edit icon.
  final bool selectionMode;

  const ServiceDirectoryScreen({super.key, this.selectionMode = false});

  @override
  State<ServiceDirectoryScreen> createState() => _ServiceDirectoryScreenState();
}

class _ServiceDirectoryScreenState extends State<ServiceDirectoryScreen> {
  final repo = InvoiceRepository();
  List<PredefinedService> services = [];
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
    if (query.trim().isEmpty) {
      services = await repo.getPredefinedServices();
    } else {
      services = await repo.searchPredefinedServices(query.trim());
    }
    if (mounted) setState(() {});
  }

  void _showAddEditServiceDialog({PredefinedService? service}) {
    final nameController = TextEditingController(text: service?.name ?? '');
    final descriptionController = TextEditingController(text: service?.description ?? '');
    final priceController = TextEditingController(text: service != null ? service.defaultPrice.toStringAsFixed(2) : '');
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newService = PredefinedService(
                  id: service?.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  defaultPrice: double.parse(priceController.text.trim()),
                );

                if (service == null) {
                  await repo.insertPredefinedService(newService);
                } else {
                  await repo.updatePredefinedService(newService);
                }

                if (mounted) {
                  Navigator.pop(context);
                  loadServices(query: searchController.text);
                }
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
            child: services.isEmpty
                ? Center(
                    child: Text(
                      searchController.text.isEmpty
                          ? "No services saved yet."
                          : "No matching services found.",
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: services.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondary.withOpacity(0.1),
                            foregroundColor: colorScheme.secondary,
                            child: const Icon(Icons.design_services_outlined),
                          ),
                          title: Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: service.description.isNotEmpty
                              ? Text(
                                  service.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Rs ${service.defaultPrice.toStringAsFixed(0)}",
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
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Service"),
                                      content: Text("Are you sure you want to delete ${service.name}?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await repo.deletePredefinedService(service.id ?? 0);
                                            if (mounted) {
                                              Navigator.pop(context);
                                              loadServices(query: searchController.text);
                                            }
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
