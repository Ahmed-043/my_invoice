import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../models/invoice_model.dart';
import '../models/service_model.dart';
import 'database_service.dart';

class InvoiceRepository {
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await DatabaseService.database;

    // Create a copy of the map so we don't accidentally mutate the original object's state
    final Map<String, dynamic> row = invoice.toMap();

    if (row['client_name'] is String) {
      row['client_name'] = (row['client_name'] as String).trim();
    }

    return await db.insert("invoices", row);
  }

  Future<void> insertServices(List<ServiceItem> services) async {
    final db = await DatabaseService.database;
    for (var service in services) {
      await db.insert("services", service.toMap());
    }
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await DatabaseService.database;
    final result = await db.query("invoices", orderBy: "id DESC");
    return result.map((e) => Invoice.fromMap(e)).toList();
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final db = await DatabaseService.database;

    if (int.tryParse(query) != null) {
      final result = await db.query("invoices", where: "id = ?", whereArgs: [query]);
      return result.map((e) => Invoice.fromMap(e)).toList();
    } else {
      final result = await db.query(
        "invoices",
        where: "client_name LIKE ? OR your_name LIKE ? OR brand_name LIKE ?",
        whereArgs: ["%$query%", "%$query%", "%$query%"],
      );
      return result.map((e) => Invoice.fromMap(e)).toList();
    }
  }

  Future<List<ServiceItem>> getServicesByInvoice(int invoiceId) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      "services",
      where: "invoice_id = ?",
      whereArgs: [invoiceId],
    );
    return result.map((e) => ServiceItem.fromMap(e)).toList();
  }
  /// Records a payment or refund.
  /// - Positive amount: adds payment received (capped at total)
  /// - Negative amount: deducts/refunds (capped so paid_amount never goes below 0)
  Future<void> recordPayment(int invoiceId, double amount) async {
    final db = await DatabaseService.database;

    // 1. Get current invoice data
    final result = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception("Invoice not found");
    }

    final map = result.first;
    final currentPaid = (map['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final total = (map['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Calculate new paid amount with caps
    double newPaid = currentPaid + amount;

    // Cap: never go below 0 or above total
    newPaid = newPaid.clamp(0.0, total);

    // 3. Determine new status
    String newStatus;
    if (newPaid >= total) {
      newStatus = 'paid';
    } else if (newPaid > 0) {
      newStatus = 'partially_paid';
    } else {
      newStatus = 'pending';
    }

    // 4. Update database
    await db.update(
      'invoices',
      {
        'paid_amount': newPaid,
        'status': newStatus,
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  /// Optional: Mark invoice as fully paid (sets paid_amount = total)
  Future<void> markInvoiceAsPaid(int invoiceId) async {
    final db = await DatabaseService.database;
    await db.update(
      'invoices',
      {
        'paid_amount': '(SELECT total FROM invoices WHERE id = ?)',
        'status': 'paid',
      },
      where: 'id = ?',
      whereArgs: [invoiceId, invoiceId],
    );
  }

  Future<File> _getInternalDbFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(join(directory.path, "invoixa.db"));
  }

  /// EXPORT: Copies 'invoixa.db' to a location of the user's choice
  Future<String?> exportDatabase() async {
    try {
      // 1. Locate the internal database
      final docDir = await getApplicationDocumentsDirectory();
      final sourceFile = File(join(docDir.path, "invoixa.db"));

      if (!await sourceFile.exists()) return "Database not found.";

      // 2. Copy to Temporary Directory (The "Neutral Zone")
      // This solves the permission issue where the system can't see internal app docs
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, "invoixa_backup.db"));

      // Write the bytes to the temp location
      await tempFile.writeAsBytes(await sourceFile.readAsBytes());

      // 3. Share from the Temp location
      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Invoixa Backup',
      );

      // 4. Clean up the temp file after sharing
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (result.status == ShareResultStatus.dismissed) return "Export cancelled";
      return "Export complete!";
    } catch (e) {
      return "Permission or Export Error: $e";
    }
  }
  /// IMPORT: Overwrites 'invoixa.db' with a file selected by the user
  Future<String?> importDatabase() async {
    try {
      // 1. Pick the backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        return "Import cancelled";
      }

      File backupFile = File(result.files.single.path!);
      File internalDbFile = await _getInternalDbFile();

      // 2. Safely close the database connection before overwriting
      final db = await DatabaseService.database;
      if (db.isOpen) {
        await db.close();
      }

      // 3. Overwrite internal file
      await backupFile.copy(internalDbFile.path);

      return "Database restored successfully! Please restart the app.";
    } catch (e) {
      return "Import failed: $e";
    }
  }

  Future<int> getClientInvoiceSequence(int invoiceId, String clientName) async {
    final db = await DatabaseService.database;

    // Counts all invoices for this client that have an ID less than or equal to this one
    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) as count 
    FROM invoices 
    WHERE client_name = ? AND id <= ?
    ''',
      [clientName, invoiceId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteInvoice(int invoiceId) async {
    final db = await DatabaseService.database;

    // Use a transaction to ensure both happen, or neither happens
    await db.transaction((txn) async {
      // 1. Delete all services linked to this invoice
      await txn.delete(
        'services',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      // 2. Delete the invoice itself
      await txn.delete(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    });
  }
}