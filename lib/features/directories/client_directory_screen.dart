import 'package:flutter/material.dart';
import '../../core/database/invoice_repository.dart';
import '../../core/models/client_model.dart';

class ClientDirectoryScreen extends StatefulWidget {
  /// When true, tapping a client will `pop()` the selected [Client] instead of opening edit.
  /// Editing remains available via the edit icon.
  final bool selectionMode;

  const ClientDirectoryScreen({super.key, this.selectionMode = false});

  @override
  State<ClientDirectoryScreen> createState() => _ClientDirectoryScreenState();
}

class _ClientDirectoryScreenState extends State<ClientDirectoryScreen> {
  final repo = InvoiceRepository();
  List<Client> clients = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadClients({String query = ''}) async {
    if (query.trim().isEmpty) {
      clients = await repo.getClients();
    } else {
      clients = await repo.searchClients(query.trim());
    }
    if (mounted) setState(() {});
  }

  void _showAddEditClientDialog({Client? client}) {
    final nameController = TextEditingController(text: client?.name ?? '');
    final companyController = TextEditingController(text: client?.companyName ?? '');
    final emailController = TextEditingController(text: client?.email ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final addressController = TextEditingController(text: client?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? "Add Client" : "Edit Client"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Client Name *"),
                  validator: (v) => v == null || v.trim().isEmpty ? "Name is required" : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: "Company/Brand Name"),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
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
                final newClient = Client(
                  id: client?.id,
                  name: nameController.text.trim(),
                  companyName: companyController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );

                if (client == null) {
                  await repo.insertClient(newClient);
                } else {
                  await repo.updateClient(newClient);
                }

                if (mounted) {
                  Navigator.pop(context);
                  loadClients(query: searchController.text);
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
        title: Text(widget.selectionMode ? "Select Client" : "Client Directory"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => loadClients(query: value),
              decoration: InputDecoration(
                hintText: "Search clients...",
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
            child: clients.isEmpty
                ? Center(
                    child: Text(
                      searchController.text.isEmpty
                          ? "No clients saved yet."
                          : "No matching clients found.",
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: clients.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withOpacity(0.1),
                            foregroundColor: colorScheme.primary,
                            child: Text(
                              client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            client.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (client.companyName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.business_rounded, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(client.companyName),
                                  ],
                                ),
                              ],
                              if (client.email.isNotEmpty || client.phone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (client.email.isNotEmpty) ...[
                                      const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          client.email,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                    if (client.phone.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        client.phone,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showAddEditClientDialog(client: client),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Client"),
                                      content: Text("Are you sure you want to delete ${client.name}?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await repo.deleteClient(client.id ?? 0);
                                            if (mounted) {
                                              Navigator.pop(context);
                                              loadClients(query: searchController.text);
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
                              Navigator.pop(context, client);
                            } else {
                              _showAddEditClientDialog(client: client);
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
        onPressed: () => _showAddEditClientDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Client"),
      ),
    );
  }
}
