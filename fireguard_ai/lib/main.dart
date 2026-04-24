import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';

// Screens
import 'pages/splash_screen.dart';

// Global Navigator Key for Notification Redirection
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Ensure Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Get login status
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Initialize Notifications
  await NotificationService().init();

  runApp(FireGuardApp(isLoggedIn: isLoggedIn));
}

class FireGuardApp extends StatelessWidget {
  final bool isLoggedIn;

  const FireGuardApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Clean UI
      title: 'Shuraksha Kavach', 

      // New Industrial Theme
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // Strict Light Mode

      // Navigation Key for Redirection
      navigatorKey: navigatorKey,

      // Smart Routing
      home: SplashScreen(isLoggedIn: isLoggedIn),
    );
  }
}
