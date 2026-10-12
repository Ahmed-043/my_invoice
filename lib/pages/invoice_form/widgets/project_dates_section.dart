import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'invoice_form_section_card.dart';

class ProjectDatesSection extends StatelessWidget {
  final DateTime issuedDate;
  final DateTime dueDate;
  final VoidCallback onPickIssuedDate;
  final VoidCallback onPickDueDate;

  const ProjectDatesSection({
    super.key,
    required this.issuedDate,
    required this.dueDate,
    required this.onPickIssuedDate,
    required this.onPickDueDate,
  });

  @override
  Widget build(BuildContext context) {
    return InvoiceFormSectionCard(
      title: "Project Dates",
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              title: Text("Start: ${DateFormat("dd MMM yyyy").format(issuedDate)}"),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: onPickIssuedDate,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListTile(
              title: Text("Due: ${DateFormat("dd MMM yyyy").format(dueDate)}"),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: onPickDueDate,
            ),
          ),
        ],
      ),
    );
  }
}
