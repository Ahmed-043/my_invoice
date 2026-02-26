import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, "invoixa.db");

    return await openDatabase(
      path,
      version: 2,  // ← bumped version to add paid_amount
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE invoices ADD COLUMN paid_amount REAL DEFAULT 0.0');
        }
      },
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT,
        your_name TEXT,
        brand_name TEXT,
        issued_date TEXT,
        due_date TEXT,
        currency_symbol TEXT,
        currency_code TEXT,
        discount REAL,
        subtotal REAL,
        total REAL,
        paid_amount REAL DEFAULT 0.0,          -- NEW FIELD
        payment_method TEXT,
        account_no TEXT,
        email TEXT,
        phone TEXT,
        status TEXT DEFAULT 'pending',
        penalty_type TEXT,
        penalty_value REAL,
        notes TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        service_name TEXT,
        quantity INTEGER,
        price REAL,
        total REAL
      )
    ''');
  }
}