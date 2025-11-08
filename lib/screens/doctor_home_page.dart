// lib/screens/doctor_home_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:relief_dental_app/main.dart'; // For supabase
import 'package:relief_dental_app/screens/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:relief_dental_app/screens/profile_pages.dart';
import 'package:relief_dental_app/screens/chat_page.dart';
import 'package:relief_dental_app/screens/video_call_page.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({Key? key}) : super(key: key);

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _allDoctors = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final patientData = await supabase
          .from('patients')
          .select('id, full_name, username, email, approved');

      final doctorData = await supabase
          .from('doctors')
          .select('id, full_name, username, email, approved');

      if (mounted) {
        setState(() {
          _allPatients = List<Map<String, dynamic>>.from(patientData);
          _allDoctors = List<Map<String, dynamic>>.from(doctorData);
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveUser(String id) async {
    try {
      final result = await supabase.rpc(
        'admin_approve_user',
        params: {'p_user_id': id},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.toString()),
          backgroundColor: Colors.green,
        ),
      );

      _fetchAllUsers();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving user: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(String id, String name, String role) async {
    final bool? didConfirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete User?'),
          content: Text(
            'Are you sure you want to permanently delete "$name"?\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didConfirm == true) {
      try {
        await supabase.rpc('delete_user_admin', params: {'user_id': id});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "$name" deleted.'),
            backgroundColor: Colors.green,
          ),
        );

        _fetchAllUsers();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- NEW: Delete All Other Users Function ---
  Future<void> _deleteAllOtherUsers(BuildContext context) async {
    final bool? didConfirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('DANGER: Delete All Users?'),
          content: Text(
            'This will permanently delete ALL users (patients and doctors), EXCEPT your admin account. Are you sure?',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text(
                'YES, DELETE ALL',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didConfirm == true) {
      try {
        // Call the secure SQL function
        final result = await supabase.rpc('delete_all_users_except_admin');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.toString()),
            backgroundColor: Colors.green,
          ),
        );

        _fetchAllUsers(); // Refresh the lists
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // ------------------------------------------

  Future<void> _signOut(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign out failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentAdminId = supabase.auth.currentUser?.id ?? '';
    final pendingPatients = _allPatients
        .where((u) => u['approved'] == false)
        .toList();
    final activePatients = _allPatients
        .where((u) => u['approved'] == true)
        .toList();
    final pendingDoctors = _allDoctors
        .where((u) => u['approved'] == false)
        .toList();
    final activeDoctors = _allDoctors
        .where((u) => u['approved'] == true)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          // --- NEW DELETE ALL BUTTON ---
          IconButton(
            icon: Icon(Icons.cleaning_services_outlined, color: Colors.red),
            tooltip: 'Delete All Other Users',
            onPressed: () => _deleteAllOtherUsers(context),
          ),
          // ---------------------------
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllUsers,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  if (_errorMessage.isNotEmpty)
                    Text(
                      'Error: $_errorMessage',
                      style: TextStyle(color: Colors.red),
                    ),

                  _buildSection(
                    title: 'Pending Patients',
                    userList: pendingPatients,
                    role: 'patient',
                    currentAdminId: currentAdminId,
                  ),

                  SizedBox(height: 24),

                  _buildSection(
                    title: 'Active Patients',
                    userList: activePatients,
                    role: 'patient',
                    currentAdminId: currentAdminId,
                  ),

                  SizedBox(height: 24),

                  _buildSection(
                    title: 'Pending Doctors',
                    userList: pendingDoctors,
                    role: 'doctor',
                    currentAdminId: currentAdminId,
                  ),

                  SizedBox(height: 24),

                  _buildSection(
                    title: 'Active Doctors',
                    userList: activeDoctors,
                    role: 'doctor',
                    currentAdminId: currentAdminId,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> userList,
    required String role,
    required String currentAdminId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${userList.length})',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Divider(height: 24),
        if (userList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'No users in this list.',
              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
            ),
          ),

        ListView.builder(
          itemCount: userList.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final user = userList[index];
            final String name = user['full_name'] ?? 'No Name';
            final String subtitle =
                '${user['username'] ?? '...'} | ${user['email'] ?? '...'}';
            final String id = user['id'];
            final bool isApproved = user['approved'] == true;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(name),
                subtitle: Text(subtitle),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminUserDetailsPage(user: user),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isApproved)
                      ElevatedButton(
                        child: Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFA5D6A7),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => _approveUser(id),
                      ),

                    SizedBox(width: 8),

                    if (id != currentAdminId)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[700],
                        ),
                        tooltip: 'Delete User',
                        onPressed: () => _deleteUser(id, name, role),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
