import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../client_directory/client_directory_screen.dart';
import '../../widgets/addable_autocomplete_field.dart';
import 'invoice_form_section_card.dart';

class ProjectClientSection extends StatelessWidget {
  final TextEditingController clientController;
  final FocusNode clientFocusNode;
  final List<String> clientNames;
  final bool showClientAddButton;
  final VoidCallback onAddClient;
  final ValueChanged<String> onClientChanged;
  final ValueChanged<String> onClientSelected;

  final TextEditingController yourNameController;
  final FocusNode yourNameFocusNode;
  final List<String> yourNames;
  final bool showYourNameAddButton;
  final VoidCallback onAddYourName;
  final ValueChanged<String> onYourNameChanged;

  final TextEditingController brandController;
  final FocusNode brandFocusNode;
  final List<String> brandNames;
  final bool showBrandAddButton;
  final VoidCallback onAddBrand;
  final ValueChanged<String> onBrandChanged;

  final TextEditingController emailController;
  final FocusNode emailFocusNode;
  final List<String> emails;
  final bool showEmailAddButton;
  final VoidCallback onAddEmail;
  final ValueChanged<String> onEmailChanged;

  final TextEditingController phoneController;
  final FocusNode phoneFocusNode;
  final List<String> phones;
  final bool showPhoneAddButton;
  final VoidCallback onAddPhone;
  final ValueChanged<String> onPhoneChanged;

  final VoidCallback onClientDirectoryReturn;

  const ProjectClientSection({
    super.key,
    required this.clientController,
    required this.clientFocusNode,
    required this.clientNames,
    required this.showClientAddButton,
    required this.onAddClient,
    required this.onClientChanged,
    required this.onClientSelected,
    required this.yourNameController,
    required this.yourNameFocusNode,
    required this.yourNames,
    required this.showYourNameAddButton,
    required this.onAddYourName,
    required this.onYourNameChanged,
    required this.brandController,
    required this.brandFocusNode,
    required this.brandNames,
    required this.showBrandAddButton,
    required this.onAddBrand,
    required this.onBrandChanged,
    required this.emailController,
    required this.emailFocusNode,
    required this.emails,
    required this.showEmailAddButton,
    required this.onAddEmail,
    required this.onEmailChanged,
    required this.phoneController,
    required this.phoneFocusNode,
    required this.phones,
    required this.showPhoneAddButton,
    required this.onAddPhone,
    required this.onPhoneChanged,
    required this.onClientDirectoryReturn,
  });

  @override
  Widget build(BuildContext context) {
    return InvoiceFormSectionCard(
      title: "Project & Client Details",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AddableAutocompleteField(
                  controller: clientController,
                  focusNode: clientFocusNode,
                  label: "Client Name",
                  options: clientNames,
                  showAddButton: showClientAddButton,
                  onAdd: onAddClient,
                  capitalization: TextCapitalization.words,
                  onChanged: onClientChanged,
                  onSelected: onClientSelected,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.people_alt_outlined),
                tooltip: "Client Directory",
                onPressed: () async {
                  final selected = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientDirectoryScreen(selectionMode: true)),
                  );
                  if (selected != null) {
                    clientController.text = selected['name'] as String? ?? '';
                    emailController.text = selected['email'] as String? ?? '';
                    phoneController.text = selected['phone'] as String? ?? '';
                    brandController.text = selected['companyName'] as String? ?? '';
                  }
                  onClientDirectoryReturn();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AddableAutocompleteField(
            controller: yourNameController,
            focusNode: yourNameFocusNode,
            label: "Your Name / Business",
            options: yourNames,
            showAddButton: showYourNameAddButton,
            onAdd: onAddYourName,
            capitalization: TextCapitalization.words,
            onChanged: onYourNameChanged,
          ),
          const SizedBox(height: 16),
          AddableAutocompleteField(
            controller: brandController,
            focusNode: brandFocusNode,
            label: "Brand Name",
            options: brandNames,
            showAddButton: showBrandAddButton,
            onAdd: onAddBrand,
            capitalization: TextCapitalization.words,
            onChanged: onBrandChanged,
          ),
          const SizedBox(height: 16),
          AddableAutocompleteField(
            controller: emailController,
            focusNode: emailFocusNode,
            label: "Email",
            options: emails,
            showAddButton: showEmailAddButton,
            onAdd: onAddEmail,
            capitalization: TextCapitalization.none,
            keyboard: TextInputType.emailAddress,
            onChanged: onEmailChanged,
          ),
          const SizedBox(height: 16),
          AddableAutocompleteField(
            controller: phoneController,
            focusNode: phoneFocusNode,
            label: "Phone",
            options: phones,
            showAddButton: showPhoneAddButton,
            onAdd: onAddPhone,
            capitalization: TextCapitalization.none,
            keyboard: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9+]*$'))],
            onChanged: onPhoneChanged,
          ),
        ],
      ),
    );
  }
}
