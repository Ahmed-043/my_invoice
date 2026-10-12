import 'package:flutter/material.dart';
import '../../../backend/supabase/supabase_service.dart';

void showAddEditServiceDialog({
  required BuildContext context,
  required SupabaseService supabaseService,
  Map<String, dynamic>? service,
  required VoidCallback onSaved,
}) {
  final nameController = TextEditingController(text: service?['name'] as String? ?? '');
  final descriptionController = TextEditingController(text: service?['description'] as String? ?? '');
  final priceController = TextEditingController(
    text: service != null ? ((service['defaultPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2) : '',
  );
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
                decoration: const InputDecoration(labelText: "Default Unit Price", prefixText: "\$ "),
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
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final name = nameController.text.trim();
              final desc = descriptionController.text.trim();
              final price = double.parse(priceController.text.trim());

              try {
                if (service == null) {
                  await supabaseService.createPredefinedService({
                    'name': name,
                    'description': desc,
                    'default_price': price,
                  });
                } else {
                  await supabaseService.updatePredefinedService(service['id'].toString(), {
                    'name': name,
                    'description': desc,
                    'default_price': price,
                  });
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  onSaved();
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text("Error saving service: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            }
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
