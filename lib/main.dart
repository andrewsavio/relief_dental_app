import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:relief_dental_app/screens/splash_screen.dart'; // <-- Import new file

// --- GLOBAL VARIABLES ---
final supabase = Supabase.instance.client;
final themeNotifier = ValueNotifier(ThemeMode.light);

// --- SUPABASE INITIALIZATION ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hkauuckcdqynbgkngwyk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrYXV1Y2tjZHF5bmJna25nd3lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1MDAzMTIsImV4cCI6MjA3ODA3NjMxMn0.XmrdQqXpDQK-dNHcNyLdwxybUvXKThk5Qoo1xvjW4_k',
  );
  runApp(ReliefDentalApp());
}

// --- ROOT APP WIDGET ---
class ReliefDentalApp extends StatelessWidget {
  const ReliefDentalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final lightTheme = ThemeData(
          brightness: Brightness.light,
          textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
          scaffoldBackgroundColor: Color(0xFFf0f4f7),
          cardColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF3E5F5),
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            elevation: 1.0,
          ),
          bottomAppBarTheme: BottomAppBarThemeData(
            color: Colors.white,
            elevation: 1.0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFA5D6A7),
            foregroundColor: Colors.black,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        );

        final darkTheme = ThemeData(
          brightness: Brightness.dark,
          textTheme: GoogleFonts.latoTextTheme(
            Theme.of(context).primaryTextTheme,
          ),
          scaffoldBackgroundColor: Color(0xFF121212),
          cardColor: Color(0xFF1E1E1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2E2E2E),
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            elevation: 1.0,
          ),
          bottomAppBarTheme: BottomAppBarThemeData(
            color: Color(0xFF2E2E2E),
            elevation: 1.0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFA5D6A7),
            foregroundColor: Colors.black,
          ),
          iconTheme: IconThemeData(color: Colors.white70),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        );

        return MaterialApp(
          title: 'Relief Dental Login',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(), // <-- Starts at the splash screen
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
