import 'package:flutter/material.dart';

void showAddEditClientDialog({
  required BuildContext context,
  Map<String, dynamic>? client,
  required Function(Map<String, dynamic> newClient) onSave,
}) {
  final nameController = TextEditingController(text: client?['name'] as String? ?? '');
  final companyController = TextEditingController(text: client?['companyName'] as String? ?? '');
  final emailController = TextEditingController(text: client?['email'] as String? ?? '');
  final phoneController = TextEditingController(text: client?['phone'] as String? ?? '');
  final addressController = TextEditingController(text: client?['address'] as String? ?? '');
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
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final newClient = {
                'id': client?['id'] ?? DateTime.now().millisecondsSinceEpoch,
                'name': nameController.text.trim(),
                'companyName': companyController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'address': addressController.text.trim(),
              };
              onSave(newClient);
              Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
