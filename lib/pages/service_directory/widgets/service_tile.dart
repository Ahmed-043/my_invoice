import 'package:flutter/material.dart';

class ServiceTile extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool selectionMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ServiceTile({
    super.key,
    required this.service,
    required this.selectionMode,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = service['name'] as String? ?? '';
    final description = service['description'] as String? ?? '';
    final defaultPrice = (service['defaultPrice'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
          foregroundColor: colorScheme.secondary,
          child: const Icon(Icons.design_services_outlined),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: description.isNotEmpty ? Text(description, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "\$ ${defaultPrice.toStringAsFixed(0)}",
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 16),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
