import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service_directory/service_directory_screen.dart';
import '../../widgets/addable_autocomplete_field.dart';
import '../../widgets/labeled_text_field.dart';
import 'service_row_data.dart';

class ServiceRowItem extends StatelessWidget {
  final ServiceRowData data;
  final int index;
  final bool canDelete;
  final List<String> serviceNames;
  final String currencySymbol;
  final VoidCallback onAddServiceValue;
  final VoidCallback onDeleteRow;
  final VoidCallback onCalculateTotal;
  final VoidCallback onServiceDirectoryReturn;

  const ServiceRowItem({
    super.key,
    required this.data,
    required this.index,
    required this.canDelete,
    required this.serviceNames,
    required this.currencySymbol,
    required this.onAddServiceValue,
    required this.onDeleteRow,
    required this.onCalculateTotal,
    required this.onServiceDirectoryReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AddableAutocompleteField(
                    controller: data.nameController,
                    focusNode: data.focusNode,
                    label: "Service Name",
                    options: serviceNames,
                    showAddButton: data.showAddButton,
                    onAdd: onAddServiceValue,
                    capitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      data.showAddButton = value.trim().isNotEmpty && !serviceNames.contains(value.trim());
                    },
                    onSelected: (_) => onCalculateTotal(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.design_services_outlined),
                  tooltip: "Service Directory",
                  onPressed: () async {
                    final selected = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(builder: (_) => const ServiceDirectoryScreen(selectionMode: true)),
                    );
                    if (selected != null) {
                      data.nameController.text = selected['name'] as String? ?? '';
                      data.priceController.text = ((selected['defaultPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0);
                      data.showAddButton = false;
                      onCalculateTotal();
                    }
                    onServiceDirectoryReturn();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LabeledTextField(
                    controller: data.quantityController,
                    label: "Quantity",
                    capitalization: TextCapitalization.none,
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onCalculateTotal(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LabeledTextField(
                    controller: data.priceController,
                    label: "Unit Price",
                    capitalization: TextCapitalization.characters,
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onCalculateTotal(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$currencySymbol ${data.total.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            if (canDelete)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDeleteRow,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
