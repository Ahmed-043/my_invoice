import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://hscqntymtxqoftnklfep.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzY3FudHltdHhxb2Z0bmtsZmVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3OTkwMTMsImV4cCI6MjEwNzM3NTAxM30.8Wz5SBAVODIVdDWK5qCq-IhwR3sn41sQS8ryBeu38Vk';
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;

  // ─── AUTHENTICATION ────────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String businessName = '',
    String phone = '',
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      final userId = response.user!.id;
      await client.from('users').upsert({
        'id': userId,
        'name': name,
        'business_name': businessName,
        'phone': phone,
        'email': email,
        'app_status': 'allowed',
        'friends': [],
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  // ─── FRIENDS MANAGEMENT ───────────────────────────────────────────────────

  Future<List<String>> getFriends() async {
    final profile = await getCurrentUserProfile();
    if (profile == null || profile['friends'] == null) return [];
    if (profile['friends'] is List) {
      return List<String>.from(profile['friends'].map((e) => e.toString()));
    }
    return [];
  }

  Future<void> addFriend(String friendUserId) async {
    final user = currentUser;
    if (user == null) throw Exception("User not authenticated");

    final currentFriends = await getFriends();
    if (!currentFriends.contains(friendUserId)) {
      currentFriends.add(friendUserId);
      await client.from('users').update({'friends': currentFriends}).eq('id', user.id);
    }
  }

  Future<void> removeFriend(String friendUserId) async {
    final user = currentUser;
    if (user == null) throw Exception("User not authenticated");

    final currentFriends = await getFriends();
    if (currentFriends.contains(friendUserId)) {
      currentFriends.remove(friendUserId);
      await client.from('users').update({'friends': currentFriends}).eq('id', user.id);
    }
  }

  // ─── PROJECTS ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProjects() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await client
        .from('projects')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData) async {
    final user = currentUser;
    if (user == null) throw Exception("User not authenticated");

    final data = Map<String, dynamic>.from(projectData);
    data['user_id'] = user.id;

    final response = await client.from('projects').insert(data).select().single();
    return response;
  }

  Future<void> updateProject(String id, Map<String, dynamic> updates) async {
    await client.from('projects').update(updates).eq('id', id);
  }

  Future<void> deleteProject(String id) async {
    await client.from('projects').delete().eq('id', id);
  }

  // ─── TASKS ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTasksForProject(String projectId) async {
    final response = await client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    final user = currentUser;
    if (user == null) throw Exception("User not authenticated");

    final data = Map<String, dynamic>.from(taskData);
    data['user_id'] = user.id;

    final response = await client.from('tasks').insert(data).select().single();
    return response;
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await client.from('tasks').update({'status': status}).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await client.from('tasks').delete().eq('id', taskId);
  }

  // ─── PAYMENT ENTRIES ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPaymentEntriesForProject(String projectId) async {
    final response = await client
        .from('payment_entries')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createPaymentEntry({
    required String projectId,
    required double amount,
    required String paymentMethod,
    String accountNo = '',
    String currencyType = 'USD',
    double discountAdjustments = 0.0,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("User not authenticated");

    final paymentData = {
      'project_id': projectId,
      'user_id': user.id,
      'account_no': accountNo,
      'payment_method': paymentMethod,
      'currency_type': currencyType,
      'discount_adjustments': discountAdjustments,
      'payment_amount': amount,
    };

    final entryResponse = await client.from('payment_entries').insert(paymentData).select().single();

    final projectResponse = await client.from('projects').select('paid_amount, total_payment').eq('id', projectId).single();
    final currentPaid = (projectResponse['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final totalPayment = (projectResponse['total_payment'] as num?)?.toDouble() ?? 0.0;

    double newPaid = (currentPaid + amount).clamp(0.0, totalPayment);
    await client.from('projects').update({'paid_amount': newPaid}).eq('id', projectId);

    return entryResponse;
  }

  // ─── PREDEFINED SERVICES ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPredefinedServices() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await client
        .from('predefined_services')
        .select()
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createPredefinedService(Map<String, dynamic> serviceData) async {
    final user = currentUser;
    if (user == null) throw Exception("User not authenticated");

    final data = Map<String, dynamic>.from(serviceData);
    data['user_id'] = user.id;

    final response = await client.from('predefined_services').insert(data).select().single();
    return response;
  }

  Future<void> updatePredefinedService(String id, Map<String, dynamic> updates) async {
    await client.from('predefined_services').update(updates).eq('id', id);
  }

  Future<void> deletePredefinedService(String id) async {
    await client.from('predefined_services').delete().eq('id', id);
  }

  // ─── SEED DUMMY DATA FOR API CONFIRMATION ───────────────────────────────

  Future<void> seedDummyData() async {
    final user = currentUser;
    if (user == null) throw Exception("Please sign in or register first to seed dummy data");

    final userId = user.id;

    // 1. Seed User Profile
    await client.from('users').upsert({
      'id': userId,
      'name': 'Alex Mercer',
      'business_name': 'Apex Digital Innovations',
      'phone': '+1 (555) 234-5678',
      'email': user.email ?? 'alex.mercer@apexdigital.com',
      'app_status': 'allowed',
      'friends': ['00000000-0000-0000-0000-000000000000'],
    });

    // 2. Seed Predefined Services
    await client.from('predefined_services').insert([
      {
        'user_id': userId,
        'name': 'Full-Stack Mobile App Development',
        'description': 'Complete cross-platform Flutter application development with cloud database backend',
        'default_price': 1200.00,
      },
      {
        'user_id': userId,
        'name': 'UI/UX Brand & Wireframe Design',
        'description': 'Comprehensive Figma design, wireframing, and custom design system creation',
        'default_price': 600.00,
      }
    ]);

    // 3. Seed Project
    final project = await client.from('projects').insert({
      'user_id': userId,
      'client_name': 'Global Solutions Inc',
      'brand_name': 'Apex Digital Innovations',
      'date_from': '2025-01-01',
      'date_to': '2025-01-31',
      'total_no_of_tasks': 3,
      'total_payment': 1800.00,
      'paid_amount': 600.00,
      'services': [
        {
          'name': 'UI/UX Brand & Wireframe Design',
          'quantity': 1,
          'unit_price': 600.00,
          'total': 600.00,
        },
        {
          'name': 'Full-Stack Mobile App Development',
          'quantity': 1,
          'unit_price': 1200.00,
          'total': 1200.00,
        }
      ],
      'shared_with': [
        {
          'user_id': '00000000-0000-0000-0000-000000000000',
          'email': 'partner@globalsolutions.com',
          'visibility': 'all'
        }
      ],
    }).select().single();

    final projectId = project['id'].toString();

    // 4. Seed Tasks for the Project
    await client.from('tasks').insert([
      {
        'project_id': projectId,
        'user_id': userId,
        'task_name': 'Design High-Fidelity Figma Wireframes',
        'status': 'completed',
      },
      {
        'project_id': projectId,
        'user_id': userId,
        'task_name': 'Backend Supabase API Integration',
        'status': 'started',
      },
      {
        'project_id': projectId,
        'user_id': userId,
        'task_name': 'QA & Flutter UI Verification',
        'status': 'pending',
      },
    ]);

    // 5. Seed Payment Entry for the Project
    await client.from('payment_entries').insert({
      'project_id': projectId,
      'user_id': userId,
      'account_no': 'US98765432101234',
      'payment_method': 'Bank Transfer',
      'currency_type': 'USD',
      'discount_adjustments': 0.00,
      'payment_amount': 600.00,
    });
  }
}
