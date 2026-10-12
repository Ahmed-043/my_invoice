import 'package:flutter/material.dart';
import 'widgets/client_tile.dart';
import 'widgets/client_form_dialog.dart';

class ClientDirectoryScreen extends StatefulWidget {
  final bool selectionMode;

  const ClientDirectoryScreen({super.key, this.selectionMode = false});

  @override
  State<ClientDirectoryScreen> createState() => _ClientDirectoryScreenState();
}

class _ClientDirectoryScreenState extends State<ClientDirectoryScreen> {
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> filteredClients = [];
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

  void loadClients({String query = ''}) {
    if (query.trim().isEmpty) {
      filteredClients = List.from(clients);
    } else {
      final q = query.trim().toLowerCase();
      filteredClients = clients.where((c) {
        final name = (c['name'] as String? ?? '').toLowerCase();
        final company = (c['companyName'] as String? ?? '').toLowerCase();
        final email = (c['email'] as String? ?? '').toLowerCase();
        return name.contains(q) || company.contains(q) || email.contains(q);
      }).toList();
    }
    if (mounted) setState(() {});
  }

  void _openClientDialog({Map<String, dynamic>? client}) {
    showAddEditClientDialog(
      context: context,
      client: client,
      onSave: (newClient) {
        if (client == null) {
          clients.add(newClient);
        } else {
          final index = clients.indexWhere((c) => c['id'] == client['id']);
          if (index != -1) clients[index] = newClient;
        }
        loadClients(query: searchController.text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            child: filteredClients.isEmpty
                ? Center(
                    child: Text(
                      searchController.text.isEmpty
                          ? "No clients saved yet."
                          : "No matching clients found.",
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredClients.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return ClientTile(
                        client: client,
                        selectionMode: widget.selectionMode,
                        onEdit: () => _openClientDialog(client: client),
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text("Delete Client"),
                              content: Text("Are you sure you want to delete ${client['name']}?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    clients.removeWhere((c) => c['id'] == client['id']);
                                    Navigator.pop(dialogContext);
                                    loadClients(query: searchController.text);
                                  },
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onTap: () {
                          if (widget.selectionMode) {
                            Navigator.pop(context, client);
                          } else {
                            _openClientDialog(client: client);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClientDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Client"),
      ),
    );
  }
}
