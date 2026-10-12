import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddableAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final List<String> options;
  final bool showAddButton;
  final VoidCallback onAdd;
  final TextCapitalization capitalization;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSelected;

  const AddableAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.options,
    required this.showAddButton,
    required this.onAdd,
    required this.capitalization,
    this.keyboard,
    this.inputFormatters,
    this.onChanged,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      focusNode: focusNode,
      textEditingController: controller,
      // Show all options when field is empty/focused
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where((option) => option.toLowerCase().contains(query));
      },
      displayStringForOption: (String option) => option,
      onSelected: (String selection) {
        controller.text = selection;
        onSelected?.call(selection);
        focusNode.unfocus();
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          textCapitalization: capitalization,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: showAddButton && fieldFocusNode.hasFocus
                ? IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Add new',
                    onPressed: () {
                      onAdd();
                      fieldFocusNode.unfocus();
                    },
                  )
                : null,
          ),
          onChanged: onChanged,
          onSubmitted: (value) {
            if (showAddButton) onAdd();
          },
        );
      },
    );
  }
}
