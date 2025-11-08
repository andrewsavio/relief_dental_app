import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:relief_dental_app/main.dart'; // For supabase & themeNotifier

// --- 1. MY PROFILE PAGE ---
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({Key? key}) : super(key: key);

  @override
  State<MyProfilePage> createState() => _MyProfilePage();
}

class _MyProfilePage extends State<MyProfilePage> {
  bool _isLoading = true;
  String? _username;
  String? _fullName;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    _email = user.email;
    try {
      // Check both tables. This is a simple way to do it.
      dynamic data;
      try {
        data = await supabase
            .from('patients')
            .select('full_name, username')
            .eq('id', user.id)
            .single();
      } catch (e) {
        data = await supabase
            .from('doctors')
            .select('full_name, username')
            .eq('id', user.id)
            .single();
      }
      _fullName = data['full_name'];
      _username = data['username'];
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Full Name'),
                  subtitle: Text(_fullName ?? 'Not set'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text('Username'),
                  subtitle: Text(_username ?? 'Not set'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email'),
                  subtitle: Text(_email ?? 'Not set'),
                ),
              ],
            ),
    );
  }
}

// --- 2. SETTINGS PAGE ---
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    // We use a ValueListenableBuilder to rebuild JUST the switch
    // when the theme changes, not the whole page.
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              final isDarkMode = currentMode == ThemeMode.dark;
              return SwitchListTile(
                title: Text('Dark Mode'),
                subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                value: isDarkMode,
                onChanged: (newValue) {
                  themeNotifier.value = newValue
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- 3. MY BILLS PAGE ---
class MyBillsPage extends StatelessWidget {
  const MyBillsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Bills')),
      body: Center(
        child: Text(
          'Your billing history will appear here.',
          style: GoogleFonts.lato(fontSize: 18),
        ),
      ),
    );
  }
}

// --- 4. LANGUAGE PAGE ---
class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selectedLanguage = 'en'; // Default language

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Language')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          RadioListTile<String>(
            title: Text('English'),
            value: 'en',
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: Text('Tamil (தமிழ்)'),
            value: 'ta',
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}

// --- 5. HELP PAGE ---
class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help & Support')),
      body: Center(
        child: Text(
          'Help and support content will go here.',
          style: GoogleFonts.lato(fontSize: 18),
        ),
      ),
    );
  }
}
