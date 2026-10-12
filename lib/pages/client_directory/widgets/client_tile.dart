import 'package:flutter/material.dart';

class ClientTile extends StatelessWidget {
  final Map<String, dynamic> client;
  final bool selectionMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ClientTile({
    super.key,
    required this.client,
    required this.selectionMode,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = client['name'] as String? ?? '';
    final companyName = client['companyName'] as String? ?? '';
    final email = client['email'] as String? ?? '';
    final phone = client['phone'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: colorScheme.primary,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'C',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (companyName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.business_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(companyName),
                ],
              ),
            ],
            if (email.isNotEmpty || phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (email.isNotEmpty) ...[
                    const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(phone, style: const TextStyle(fontSize: 12)),
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
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
