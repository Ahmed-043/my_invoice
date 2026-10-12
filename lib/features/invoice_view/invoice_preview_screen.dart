import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../invoice_form/widgets/accent_color_dot.dart';
import '../invoice_form/widgets/invoice_template_card.dart';
import 'delete_dialog.dart';
import 'invoice_preview_widget.dart';

class InvoiceViewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> invoice;
  final List<Map<String, dynamic>> services;
  final int clientInvoiceSequence;
  final VoidCallback callBack;

  const InvoiceViewScreen({
    super.key,
    required this.invoice,
    required this.services,
    required this.clientInvoiceSequence,
    required this.callBack,
  });

  @override
  ConsumerState<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends ConsumerState<InvoiceViewScreen> {
  final GlobalKey invoiceKey = GlobalKey();
  bool isLoading = false;
  late bool showTracking = false;
  late int clientInvoiceSequence = widget.clientInvoiceSequence;
  late Map<String, dynamic> currentInvoice;

  @override
  void initState() {
    super.initState();
    currentInvoice = Map<String, dynamic>.from(widget.invoice);
  }

  void _updateStyles(String templateStyle, String accentColor) {
    setState(() {
      currentInvoice['templateStyle'] = templateStyle;
      currentInvoice['accentColor'] = accentColor;
    });
    widget.callBack.call();
  }

  void _showStyleBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeProvider);
            final isDark = themeMode == ThemeMode.dark;
            final templateStyle = currentInvoice['templateStyle'] as String? ?? 'classic';
            final accentColor = currentInvoice['accentColor'] as String? ?? 'default';

            return Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Customize Invoice", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Dark Mode", style: Theme.of(context).textTheme.titleMedium),
                            Switch(
                              value: isDark,
                              onChanged: (val) {
                                ref.read(themeProvider.notifier).toggleTheme();
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Text("Template Design", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InvoiceTemplateCard(
                                label: "Classic",
                                description: "Minimalist",
                                icon: Icons.border_all_rounded,
                                isSelected: templateStyle == 'classic',
                                onSelected: () {
                                  _updateStyles('classic', accentColor);
                                  setModalState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InvoiceTemplateCard(
                                label: "Modern",
                                description: "Professional",
                                icon: Icons.dashboard_rounded,
                                isSelected: templateStyle == 'modern',
                                onSelected: () {
                                  _updateStyles('modern', accentColor);
                                  setModalState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InvoiceTemplateCard(
                                label: "Bold",
                                description: "Editorial",
                                icon: Icons.view_headline_rounded,
                                isSelected: templateStyle == 'bold',
                                onSelected: () {
                                  _updateStyles('bold', accentColor);
                                  setModalState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text("Accent Color", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              AccentColorDot(
                                color: Colors.blueGrey,
                                label: 'Slate',
                                isSelected: accentColor == 'default',
                                onSelected: () {
                                  _updateStyles(templateStyle, 'default');
                                  setModalState(() {});
                                },
                              ),
                              AccentColorDot(
                                color: Colors.indigo,
                                label: 'Blue',
                                isSelected: accentColor == 'blue',
                                onSelected: () {
                                  _updateStyles(templateStyle, 'blue');
                                  setModalState(() {});
                                },
                              ),
                              AccentColorDot(
                                color: Colors.teal,
                                label: 'Green',
                                isSelected: accentColor == 'green',
                                onSelected: () {
                                  _updateStyles(templateStyle, 'green');
                                  setModalState(() {});
                                },
                              ),
                              AccentColorDot(
                                color: Colors.amber[700]!,
                                label: 'Gold',
                                isSelected: accentColor == 'gold',
                                onSelected: () {
                                  _updateStyles(templateStyle, 'gold');
                                  setModalState(() {});
                                },
                              ),
                              AccentColorDot(
                                color: Colors.deepOrangeAccent,
                                label: 'Red',
                                isSelected: accentColor == 'red',
                                onSelected: () {
                                  _updateStyles(templateStyle, 'red');
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void shareInvoice() {
    _showSnackBar("Share button pressed");
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final id = currentInvoice['id'];

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              showTracking = !showTracking;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
            child: Text("Invoice #$id"),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: "Edit Style",
              onPressed: _showStyleBottomSheet,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => DeleteConfirmationDialog(
                    onConfirm: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                      widget.callBack.call();
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                alignment: null,
                clipBehavior: Clip.hardEdge,
                minScale: 1.0,
                maxScale: 4.0,
                boundaryMargin: EdgeInsets.zero,
                constrained: true,
                child: Hero(
                  tag: "invoice-$id",
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: RepaintBoundary(
                            key: invoiceKey,
                            child: InvoicePreviewWidget(
                              invoice: currentInvoice,
                              services: widget.services,
                              clientInvoiceSequence: clientInvoiceSequence,
                              showTracking: showTracking,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 350,
                height: 56,
                child: ElevatedButton(
                  onPressed: shareInvoice,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        const Expanded(child: SizedBox(height: 30, child: CircularProgressIndicator())),
                      if (!isLoading)
                        const SizedBox(width: 10),
                      if (!isLoading)
                        const Text("Share", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
