import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../models/invoice_model.dart';
import '../models/service_model.dart';
import '../models/client_model.dart';
import '../models/predefined_service_model.dart';
import 'database_service.dart';

class InvoiceRepository {
  // ─── INVOICES ──────────────────────────────────────────────────────────────

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await DatabaseService.database;

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

  Future<void> recordPayment(int invoiceId, double amount) async {
    final db = await DatabaseService.database;

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

    double newPaid = currentPaid + amount;
    newPaid = newPaid.clamp(0.0, total);

    String newStatus;
    if (newPaid >= total) {
      newStatus = 'paid';
    } else if (newPaid > 0) {
      newStatus = 'partially_paid';
    } else {
      newStatus = 'pending';
    }

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

  Future<void> updateInvoiceStyles(int invoiceId, String templateStyle, String accentColor) async {
    final db = await DatabaseService.database;
    await db.update(
      'invoices',
      {
        'template_style': templateStyle,
        'accent_color': accentColor,
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<int> getClientInvoiceSequence(int invoiceId, String clientName) async {
    final db = await DatabaseService.database;

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

    await db.transaction((txn) async {
      await txn.delete(
        'services',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      await txn.delete(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    });
  }

  // ─── CLIENTS DIRECTORY ──────────────────────────────────────────────────────

  Future<List<Client>> getClients() async {
    final db = await DatabaseService.database;
    final result = await db.query("clients", orderBy: "name ASC");
    return result.map((e) => Client.fromMap(e)).toList();
  }

  Future<List<Client>> searchClients(String query) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      "clients",
      where: "name LIKE ? OR company_name LIKE ? OR email LIKE ?",
      whereArgs: ["%$query%", "%$query%", "%$query%"],
      orderBy: "name ASC",
    );
    return result.map((e) => Client.fromMap(e)).toList();
  }

  Future<int> insertClient(Client client) async {
    final db = await DatabaseService.database;
    return await db.insert(
      "clients",
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateClient(Client client) async {
    final db = await DatabaseService.database;
    return await db.update(
      "clients",
      client.toMap(),
      where: "id = ?",
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await DatabaseService.database;
    return await db.delete(
      "clients",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ─── PREDEFINED SERVICES DIRECTORY ──────────────────────────────────────────

  Future<List<PredefinedService>> getPredefinedServices() async {
    final db = await DatabaseService.database;
    final result = await db.query("predefined_services", orderBy: "name ASC");
    return result.map((e) => PredefinedService.fromMap(e)).toList();
  }

  Future<List<PredefinedService>> searchPredefinedServices(String query) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      "predefined_services",
      where: "name LIKE ? OR description LIKE ?",
      whereArgs: ["%$query%", "%$query%"],
      orderBy: "name ASC",
    );
    return result.map((e) => PredefinedService.fromMap(e)).toList();
  }

  Future<int> insertPredefinedService(PredefinedService service) async {
    final db = await DatabaseService.database;
    return await db.insert(
      "predefined_services",
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePredefinedService(PredefinedService service) async {
    final db = await DatabaseService.database;
    return await db.update(
      "predefined_services",
      service.toMap(),
      where: "id = ?",
      whereArgs: [service.id],
    );
  }

  Future<int> deletePredefinedService(int id) async {
    final db = await DatabaseService.database;
    return await db.delete(
      "predefined_services",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ─── DATABASE EXPORT & IMPORT ──────────────────────────────────────────────

  Future<File> _getInternalDbFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(join(directory.path, "invoixa.db"));
  }

  Future<String?> exportDatabase() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final sourceFile = File(join(docDir.path, "invoixa.db"));

      if (!await sourceFile.exists()) return "Database not found.";

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, "invoixa_backup.db"));

      await tempFile.writeAsBytes(await sourceFile.readAsBytes());

      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Invoixa Backup',
      );

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (result.status == ShareResultStatus.dismissed) return "Export cancelled";
      return "Export complete!";
    } catch (e) {
      return "Permission or Export Error: $e";
    }
  }

  Future<String?> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        return "Import cancelled";
      }

      File backupFile = File(result.files.single.path!);
      File internalDbFile = await _getInternalDbFile();

      final db = await DatabaseService.database;
      if (db.isOpen) {
        await db.close();
      }

      await backupFile.copy(internalDbFile.path);

      return "Database restored successfully! Please restart the app.";
    } catch (e) {
      return "Import failed: $e";
    }
  }
}