// lib/screens/login_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:relief_dental_app/main.dart'; // To get 'supabase'
import 'package:relief_dental_app/screens/patient_home_page.dart';
import 'package:relief_dental_app/screens/doctor_home_page.dart';
import 'package:relief_dental_app/screens/standard_doctor_home_page.dart';
import 'package:async/async.dart'; // For CancelableOperation, though actual usage is simplified

enum UserRole { patient, doctor }

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;

  bool _isPasswordObscured = true;

  CancelableOperation? _usernameCheckOperation;

  static const Color dentalGreen = Color(0xFF00796B);

  // --- SIGN UP FUNCTION ---
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final role = _selectedRole == UserRole.patient ? 'patient' : 'doctor';

      // 1. Check if username is taken
      final bool usernameExists = await supabase.rpc(
        'username_exists',
        params: {'p_username': username},
      );

      if (usernameExists) {
        throw Exception('That username is already taken.');
      }

      // 2. Sign up the user (creates user in auth.users)
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _fullNameController.text.trim(),
          'username': username,
          'role': role,
        },
      );

      final newUserId = authResponse.user?.id;

      // 3. CRITICAL FIX: MANUALLY INSERT PROFILE (Bypasses the broken database trigger)
      if (newUserId != null) {
        final String tableName = role == 'patient' ? 'patients' : 'doctors';

        await supabase.from(tableName).insert({
          'id': newUserId.toString(),
          'full_name': _fullNameController.text.trim(),
          'username': username,
          'email': _emailController.text.trim(),
          'approved': false, // Starts as false
        });
      }

      // 4. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign-up successful! Your account is now pending admin approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _emailController.clear();
        _passwordController.clear();
        _usernameController.clear();
        _fullNameController.clear();
        setState(() => _isLogin = true);
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  // --- SIGN IN FUNCTION ---
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String identifier = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // 1. Find email from username/email identifier
      final String? foundEmail = await supabase.rpc(
        'get_user_email_from_identifier',
        params: {'p_identifier': identifier},
      );

      if (foundEmail == null) {
        throw Exception('User not found.');
      }

      // 2. Sign in with the found email
      final AuthResponse authResponse = await supabase.auth.signInWithPassword(
        email: foundEmail,
        password: password,
      );

      // 3. Check role and status after successful sign-in
      if (mounted && authResponse.user != null) {
        final String actualStatus =
            await supabase.rpc('check_user_status') as String;

        // 4. ROLE ISOLATION CHECK: If patient is trying to log in as doctor/admin, block them.
        if (_selectedRole == UserRole.patient &&
            (actualStatus == 'doctor' ||
                actualStatus == 'admin' ||
                actualStatus == 'standard_doctor')) {
          await supabase.auth.signOut();
          throw Exception(
            'Login failed. You are a Doctor. Please switch the toggle.',
          );
        }

        // 5. Navigate based on the actual, approved role
        if (!mounted) return;
        switch (actualStatus) {
          case 'patient':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientHomePage()),
            );
            break;
          case 'admin': // Admin is the highest form of 'doctor'
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorHomePage(),
              ), // Admin Dashboard
            );
            break;
          case 'standard_doctor': // Standard Doctor Role
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StandardDoctorHomePage(),
              ), // Standard Dashboard
            );
            break;
          case 'pending':
            await supabase.auth.signOut();
            throw Exception('Your account is pending approval by an admin.');
          case 'unknown':
          default:
            await supabase.auth.signOut();
            throw Exception('Could not verify access role.');
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _usernameCheckOperation?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // <-- FIX 1: Set Scaffold transparent
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // <-- FIX 2: Set AppBar transparent
        elevation: 0, // Remove shadow
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: const Icon(
            Icons.health_and_safety,
            size: 36.0,
            color: dentalGreen,
          ),
        ),
        title: Text(
          'RELIEF DENTAL HOSPITAL',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            color: dentalGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(24.0),
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment(
                            value: UserRole.patient,
                            label: Text('Patient'),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment(
                            value: UserRole.doctor,
                            label: Text('Doctor'),
                            icon: Icon(Icons.medical_services),
                          ),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (Set<UserRole> newSelection) {
                          setState(() {
                            _isLogin = true;
                            _formKey.currentState?.reset();
                            _emailController.clear();
                            _passwordController.clear();
                            _selectedRole = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 24.0),

                      Text(
                        _isLogin
                            ? '${_selectedRole == UserRole.patient ? 'Patient' : 'Doctor'} Login'
                            : 'Create ${_selectedRole == UserRole.patient ? 'Patient' : 'Doctor'} Account',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.color,
                        ),
                      ),
                      const SizedBox(height: 48.0),

                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            hintText: 'Full Name',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20.0),
                      ],
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: _isLogin
                              ? 'Email or Username'
                              : 'Email', // Dynamic hint
                          prefixIcon: Icon(
                            _isLogin
                                ? Icons.person_search
                                : Icons.email_outlined,
                          ), // Dynamic icon
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                        ),
                        keyboardType: TextInputType.text, // Allow any text
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email or username';
                          }
                          // Only check for '@' if signing up
                          if (!_isLogin && !value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32.0),
                      ElevatedButton(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6A1B9A),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isLogin ? 'Login' : 'Sign Up',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        onPressed: _isLoading
                            ? null
                            : (_isLogin ? _signIn : _signUp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF1EDFF),
                          foregroundColor: Color(0xFF6A1B9A),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () {
                          _formKey.currentState?.reset();
                          _emailController.clear();
                          _passwordController.clear();
                          _usernameController.clear();
                          _fullNameController.clear();
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Don\'t have an account? Sign Up'
                              : 'Already have an account? Login',
                          style: TextStyle(color: dentalGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
