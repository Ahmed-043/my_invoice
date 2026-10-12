import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/theme_provider.dart';
import 'features/splash/splash_screen.dart';
import 'services/supabase_service.dart';

Future<void> createNewUserFromAppCode() async {
  debugPrint('==================================================');
  debugPrint('👤 [CREATING NEW USER VIA APP CODE]');
  debugPrint('==================================================');

  final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
  final email = 'user_$timestamp@invoixa.org';
  const password = 'Password123!';

  try {
    final response = await SupabaseService().signUp(
      email: email,
      password: password,
      name: 'App User $timestamp',
      businessName: 'App Studios $timestamp',
      phone: '+1 (555) $timestamp',
    );

    debugPrint('✅ USER CREATED SUCCESSFULLY FROM APP CODE!');
    debugPrint('Email: $email');
    debugPrint('User ID: ${response.user?.id}');
    debugPrint('==================================================');
  } catch (e) {
    debugPrint('❌ USER CREATION ERROR: $e');
    debugPrint('==================================================');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Create new user directly via app code
  await createNewUserFromAppCode();

  // Show status bar (top) but hide navigation bar (bottom)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.top],
  );

  runApp(const ProviderScope(child: InvoixaApp()));
}

class InvoixaApp extends ConsumerWidget {
  const InvoixaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoixa',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
