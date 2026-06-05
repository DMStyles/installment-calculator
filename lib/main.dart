import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';
import 'home_screen.dart';
import 'notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper.init();

  final settings = AppSettings();
  await settings.load();

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

    final darkTheme = ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF111827),
        primary: Colors.blue,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );

    final lightTheme = ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFF3F4F6),
        primary: Colors.blue,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
      ),
      cardColor: Colors.white,
    );

    return MaterialApp(
      title: 'Installment Hub',
      debugShowCheckedModeBanner: false,
      theme: isDark ? darkTheme : lightTheme,
      home: const HomeScreen(),
    );
  }
}
