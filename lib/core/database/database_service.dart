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
      version: 3,  // ← bumped version to 3 for directories and templates
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE invoices ADD COLUMN paid_amount REAL DEFAULT 0.0');
        }
        if (oldVersion < 3) {
          // Add styling fields to invoices
          await db.execute("ALTER TABLE invoices ADD COLUMN template_style TEXT DEFAULT 'classic'");
          await db.execute("ALTER TABLE invoices ADD COLUMN accent_color TEXT DEFAULT 'default'");

          // Create new directory tables
          await db.execute('''
            CREATE TABLE clients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE,
              email TEXT,
              phone TEXT,
              company_name TEXT,
              address TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE predefined_services (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE,
              description TEXT,
              default_price REAL
            )
          ''');

          // Extract existing unique clients and services to pre-populate directories
          try {
            final List<Map<String, dynamic>> existingInvoices = await db.query('invoices');
            final Set<String> processedClients = {};
            for (var invoice in existingInvoices) {
              final name = (invoice['client_name'] as String?)?.trim();
              if (name != null && name.isNotEmpty && !processedClients.contains(name.toLowerCase())) {
                processedClients.add(name.toLowerCase());
                final email = invoice['email'] as String? ?? '';
                final phone = invoice['phone'] as String? ?? '';
                final company = invoice['brand_name'] as String? ?? '';
                
                await db.insert('clients', {
                  'name': name,
                  'email': email,
                  'phone': phone,
                  'company_name': company,
                  'address': '',
                });
              }
            }
          } catch (e) {
            print("Migration client extraction error: $e");
          }

          try {
            final List<Map<String, dynamic>> existingServices = await db.query('services');
            final Set<String> processedServices = {};
            for (var service in existingServices) {
              final name = (service['service_name'] as String?)?.trim();
              if (name != null && name.isNotEmpty && !processedServices.contains(name.toLowerCase())) {
                processedServices.add(name.toLowerCase());
                final price = (service['price'] as num?)?.toDouble() ?? 0.0;
                
                await db.insert('predefined_services', {
                  'name': name,
                  'description': '',
                  'default_price': price,
                });
              }
            }
          } catch (e) {
            print("Migration service extraction error: $e");
          }
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
        paid_amount REAL DEFAULT 0.0,
        payment_method TEXT,
        account_no TEXT,
        email TEXT,
        phone TEXT,
        status TEXT DEFAULT 'pending',
        penalty_type TEXT,
        penalty_value REAL,
        notes TEXT,
        created_at TEXT,
        template_style TEXT DEFAULT 'classic',
        accent_color TEXT DEFAULT 'default'
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

    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        email TEXT,
        phone TEXT,
        company_name TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE predefined_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        description TEXT,
        default_price REAL
      )
    ''');
  }
}