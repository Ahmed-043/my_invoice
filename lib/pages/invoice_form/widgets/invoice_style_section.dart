import 'package:flutter/material.dart';
import '../../widgets/accent_color_dot.dart';
import '../../widgets/invoice_template_card.dart';
import 'invoice_form_section_card.dart';

class InvoiceStyleSection extends StatelessWidget {
  final String templateStyle;
  final ValueChanged<String> onSelectTemplate;
  final String accentColor;
  final ValueChanged<String> onSelectAccentColor;

  const InvoiceStyleSection({
    super.key,
    required this.templateStyle,
    required this.onSelectTemplate,
    required this.accentColor,
    required this.onSelectAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InvoiceFormSectionCard(
      title: "Invoice Style & Accent Color",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Template Design", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InvoiceTemplateCard(
                  label: "Classic Minimalist",
                  description: "Clean black lines",
                  icon: Icons.border_all_rounded,
                  isSelected: templateStyle == 'classic',
                  onSelected: () => onSelectTemplate('classic'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InvoiceTemplateCard(
                  label: "Modern Professional",
                  description: "Accent block layout",
                  icon: Icons.dashboard_rounded,
                  isSelected: templateStyle == 'modern',
                  onSelected: () => onSelectTemplate('modern'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InvoiceTemplateCard(
                  label: "Bold Editorial",
                  description: "Solid banner header",
                  icon: Icons.view_headline_rounded,
                  isSelected: templateStyle == 'bold',
                  onSelected: () => onSelectTemplate('bold'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text("Accent Color", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AccentColorDot(
                color: Colors.blueGrey,
                label: 'Slate',
                isSelected: accentColor == 'default',
                onSelected: () => onSelectAccentColor('default'),
              ),
              AccentColorDot(
                color: Colors.indigo,
                label: 'Blue',
                isSelected: accentColor == 'blue',
                onSelected: () => onSelectAccentColor('blue'),
              ),
              AccentColorDot(
                color: Colors.teal,
                label: 'Green',
                isSelected: accentColor == 'green',
                onSelected: () => onSelectAccentColor('green'),
              ),
              AccentColorDot(
                color: Colors.amber[700]!,
                label: 'Gold',
                isSelected: accentColor == 'gold',
                onSelected: () => onSelectAccentColor('gold'),
              ),
              AccentColorDot(
                color: Colors.deepOrangeAccent,
                label: 'Red',
                isSelected: accentColor == 'red',
                onSelected: () => onSelectAccentColor('red'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
