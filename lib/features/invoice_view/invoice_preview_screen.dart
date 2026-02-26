import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../core/database/invoice_repository.dart';
import '../../core/models/invoice_model.dart';
import '../../core/models/service_model.dart';
import 'delete_dialog.dart';
import 'invoice_preview_widget.dart';

class InvoiceViewScreen extends StatefulWidget {
  final Invoice invoice;
  final List<ServiceItem> services;
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
  State<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends State<InvoiceViewScreen> {
  final GlobalKey invoiceKey = GlobalKey();
  bool isLoading = false;
  late bool showTracking =  false;
  late int clientInvoiceSequence = widget.clientInvoiceSequence;

  Future<Uint8List?> _cropCaptureInvoice() async {
    try {
      final boundary = invoiceKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      await Future.delayed(const Duration(milliseconds: 120));

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Decode → apply rounded corners + transparent bg → encode back
      img.Image? imgImage = img.decodePng(pngBytes);
      if (imgImage == null) return pngBytes;

      // Create a new image with rounded corners (transparent outside)
      final rounded = img.copyCropCircle(
        imgImage,
        radius: (imgImage.width / 2).toInt(), // full circle, or use smaller for softer round
      );

      // OR: for exact 16px radius rounded rect (recommended)
      final roundedRect = img.copyCrop(
        imgImage,
        x: 0,
        y: 0,
        width: imgImage.width,
        height: imgImage.height,
        radius: 16 * 3, // × pixelRatio to match screen radius
        antialias: true,
      );

      // Make sure background is transparent (if not already)
      // Usually already transparent if widget bg was transparent

      pngBytes = img.encodePng(roundedRect);

      return pngBytes;
    } catch (e) {
      debugPrint("Capture failed: $e");
      return null;
    }
  }

  Future<Uint8List?> _captureInvoice() async {
    try {
      final boundary = invoiceKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      await Future.delayed(const Duration(milliseconds: 120));

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Capture failed: $e");
      return null;
    }
  }

  Future<void> shareInvoice() async {
    setState(() {
      isLoading = true;
    });
    final bytes = await _captureInvoice();
    if (bytes == null || !mounted) {
      _showSnackBar("Failed to capture invoice");
      return;
    }

    try {
      // 1. Save temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/invoice_${widget.invoice.id}.png';
      final file = File(tempPath);
      await file.writeAsBytes(bytes);
      final xFile = XFile(file.path);

      // 2. Share
      await Share.shareXFiles(
        [xFile],
        text: 'Invoice #${widget.invoice.id}',
        subject: 'Invoice from ${widget.invoice.yourName}',
      );

      // 3. Copy image to clipboard using super_clipboard
      bool copied = false;

      try {
        final clipboard = SystemClipboard.instance;
        if (clipboard != null) {
          final item = DataWriterItem(suggestedName: 'Invoice #${widget.invoice.id}.png');
          item.add(Formats.png(bytes));  // ← this is the correct way
          await clipboard.write([item]);
          copied = true;
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        debugPrint("Clipboard copy failed: $e");
      }

      // 4. Feedback
      if (copied) {
        //_showSnackBar("Shared image copied to clipboard");
      } else {
       // _showSnackBar("Shared successfully (clipboard copy not available)");
      }
    } catch (e) {
      debugPrint("Share error: $e");
      setState(() {
        isLoading = false;
      });
      _showSnackBar("Operation failed");
    }
    setState(() {
      isLoading = false;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(

          title: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: (){
              setState(() {
                showTracking = !showTracking;
              });
            },
              child: Padding(
                padding: const EdgeInsets.only(left :12,right: 12,bottom: 4),
                child: Text("Invoice #${widget.invoice.id}"),
              )),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false, // Prevent closing by tapping outside during countdown
                  builder: (context) => DeleteConfirmationDialog(
                    onConfirm: () async {
                      final repo = InvoiceRepository();
                      await repo.deleteInvoice(widget.invoice.id ?? 0);
                      if (mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back from detail screen
                      }
                      widget.callBack.call();
                    },
                  ),
                );
              },            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(

                // 1. alignment null allows focal-point zooming (mouse/finger position)
                alignment: null,
                clipBehavior: Clip.hardEdge,
                minScale: 1.0, // Set to 1.0 so they can't shrink it smaller than the screen
                maxScale: 4.0,
                // 2. Setting margin to zero keeps the widget edges locked inside the viewport
                boundaryMargin: EdgeInsets.zero,
                // 3. constrained: true is vital to keep the child within the parent's size
                constrained: true,
                child: Hero(
                  tag: "invoice-${widget.invoice.id}",
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
                              invoice: widget.invoice,
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
                  child:  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(isLoading)
                        const Expanded(child: SizedBox(height: 30,child: CircularProgressIndicator())),
                      if(!isLoading)
                        const SizedBox(width: 10,),
                      if(!isLoading)
                        const Text("Share",style: TextStyle(fontSize: 20),),
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