import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';
import 'firebase_service.dart';
import 'home_screen.dart';
import 'notification_helper.dart';

/// Handles FCM messages that arrive when the app is in the background/terminated.
/// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseService.init();
  // flutter_local_notifications shows the notification visually
  await NotificationHelper.showFcmNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Firebase (and request FCM permission + get token)
  await FirebaseService.init();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Init local notifications plugin (still used to display FCM messages)
  await NotificationHelper.init();

  // Listen for FCM messages when app is in foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationHelper.showFcmNotification(message);
  });

  final settings = AppSettings();
  await settings.load();

  // Sync settings to Firestore on startup
  await FirebaseService.updateDeviceSettings(
    enabled: settings.notificationsEnabled,
    leadDays: settings.notificationLeadDays,
  );

  runApp(
    ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: const InstallmentApp(),
    ),
  );
}


class InstallmentApp extends StatelessWidget {
  const InstallmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFA8C7FA),
        onPrimary: Color(0xFF062E6F),
        primaryContainer: Color(0xFF0842A0),
        onPrimaryContainer: Color(0xFFD3E3FD),
        surface: Color(0xFF121318),
        onSurface: Color(0xFFE3E2E6),
        surfaceContainerHighest: Color(0xFF2E3036),
      ),
      scaffoldBackgroundColor: const Color(0xFF121318),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E2025),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0B57D0),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD3E3FD),
        onPrimaryContainer: Color(0xFF041E49),
        surface: Color(0xFFF8F9FA),
        onSurface: Color(0xFF1F1F1F),
        surfaceContainerHighest: Color(0xFFE1E2EC),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1F1F1F),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );

    return MaterialApp(
      title: 'Installment Hub',
      debugShowCheckedModeBanner: false,
      theme: isDark ? darkTheme : lightTheme,
      home: const HomeScreen(),
    );
  }
}
