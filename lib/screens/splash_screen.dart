// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:relief_dental_app/screens/login_page.dart';
import 'package:relief_dental_app/screens/patient_home_page.dart';
import 'package:relief_dental_app/screens/doctor_home_page.dart';
import 'package:relief_dental_app/screens/standard_doctor_home_page.dart';
import 'package:relief_dental_app/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the redirection immediately
    _redirectAfterDelay();
  }

  void _redirectAfterDelay() {
    // CRITICAL CHANGE: Shorten delay and check session immediately
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      // 1. Get the current session (Supabase automatically loads this from storage)
      final session = supabase.auth.currentSession;

      if (session == null) {
        // If no session exists, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }

      // 2. Session exists: Check the user's role to redirect correctly
      try {
        final role = await supabase.rpc('check_user_status') as String;

        if (role == 'patient') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PatientHomePage()),
          );
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DoctorHomePage()),
          );
        } else if (role == 'standard_doctor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const StandardDoctorHomePage(),
            ),
          );
        } else {
          // If role is 'pending' or 'unknown', send to login (and clear the session)
          await supabase.auth.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } catch (e) {
        // Error fetching role (e.g., network error). Send to login.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (Your existing logo display logic is fine)
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Image.asset(
          'assets/images/logo.jpg',
          width: 250,
          height: 250,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                'Error: Could not load logo.jpg\nCheck assets/images/ and pubspec.yaml',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
            );
          },
        ),
      ),
    );
  }
}
