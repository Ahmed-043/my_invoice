final Map<String, Map<String, String>> dbSchema = {
  'users': {
    'id': 'TEXT PRIMARY KEY',
    'name': 'TEXT NOT NULL',
    'business_name': 'TEXT DEFAULT ""',
    'phone': 'TEXT DEFAULT ""',
    'email': 'TEXT NOT NULL',
    'app_status': "TEXT CHECK(app_status IN ('allowed','banned')) NOT NULL DEFAULT 'allowed'",
    'friends': 'TEXT NOT NULL DEFAULT "[]"', // JSON array string of friend user IDs: ["uuid1", "uuid2"]
    'created_at': 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
    'updated_at': 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
  },

  'projects': {
    'id': 'TEXT PRIMARY KEY',
    'user_id': 'TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE',
    'client_name': 'TEXT NOT NULL DEFAULT ""',
    'brand_name': 'TEXT DEFAULT ""',
    'date_from': 'TEXT DEFAULT ""',
    'date_to': 'TEXT DEFAULT ""',
    'total_no_of_tasks': 'INTEGER DEFAULT 0',
    'total_payment': 'REAL DEFAULT 0',
    'paid_amount': 'REAL DEFAULT 0',
    'services': 'TEXT NOT NULL DEFAULT "[]"',
    'shared_with': 'TEXT NOT NULL DEFAULT "[]"', // JSON array: [{"user_id": "...", "visibility": "all|tasks|payments"}]
    'created_at': 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
    'updated_at': 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
  },

  'tasks': {
    'id': 'TEXT PRIMARY KEY',
    'project_id': 'TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE',
    'user_id': 'TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE',
    'task_name': 'TEXT NOT NULL',
    'status': "TEXT CHECK(status IN ('started','pending','completed','cancelled')) NOT NULL DEFAULT 'pending'",
    'created_at': 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
    'updated_at': 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
  },

  'payment_entries': {
    'id': 'TEXT PRIMARY KEY',
    'project_id': 'TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE',
    'user_id': 'TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE',
    'account_no': 'TEXT DEFAULT ""',
    'payment_method': 'TEXT NOT NULL DEFAULT "Bank Transfer"',
    'currency_type': 'TEXT NOT NULL DEFAULT "USD"',
    'discount_adjustments': 'REAL DEFAULT 0',
    'payment_amount': 'REAL NOT NULL DEFAULT 0',
    'status': "TEXT CHECK(status IN ('paid','unpaid','Paid','Unpaid')) NOT NULL DEFAULT 'unpaid'",
    'created_at': 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
  },

  'predefined_services': {
    'id': 'TEXT PRIMARY KEY',
    'user_id': 'TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE',
    'name': 'TEXT NOT NULL',
    'description': 'TEXT DEFAULT ""',
    'default_price': 'REAL DEFAULT 0',
    'created_at': 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
  },
};
