
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:milkman/adminloginpage.dart';
import 'firebase_options.dart';
import 'dairy_form_page.dart';
import 'customer_portal_page.dart';
import 'splash_page.dart';
import 'login_page.dart';
import 'customer_signup_page.dart';
import 'app_theme.dart';
import 'package:flutter/foundation.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Dark Mode Preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  // ✅ Initialize Firebase before running the app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ (Optional) Test Firestore connection
  try {
    await FirebaseFirestore.instance.collection('test').doc('connection').set({
      'status': 'connected',
      'timestamp': DateTime.now(),
    });
    print('✅ Firestore connection successful');
  } catch (e) {
    print('❌ Firestore connection failed: $e');
  }

  runApp(const SmartMilkmanApp());
}

class SmartMilkmanApp extends StatelessWidget {
  const SmartMilkmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Smart Milkman',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          darkTheme: ThemeData.dark(),
          themeMode: currentMode,

          // ✅ Start from Splash Page
          //initialRoute: '/splash',
          initialRoute: kIsWeb ? '/admin' : '/splash',

          routes: {
            '/admin': (context) => const AdminLoginPage(),
            '/splash': (context) => const SplashPage(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const CustomerSignupPage(),
            '/dairy-form': (context) => const DairyFormPage(),
            '/customer-portal': (context) => const CustomerPortalPage(),
          },
        );
      },
    );
  }
}
