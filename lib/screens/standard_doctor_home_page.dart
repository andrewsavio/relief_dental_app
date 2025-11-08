import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:relief_dental_app/main.dart'; // For supabase
import 'package:relief_dental_app/screens/login_page.dart';
import 'package:relief_dental_app/screens/doctor_appointment_details_page.dart';
import 'package:relief_dental_app/screens/chat_page.dart';
import 'package:relief_dental_app/screens/video_call_page.dart';

// --- MODIFIED CLASS DEFINITION ---
class StandardDoctorHomePage extends StatefulWidget {
  const StandardDoctorHomePage({Key? key}) : super(key: key);

  @override
  State<StandardDoctorHomePage> createState() => _StandardDoctorHomePageState();
}

class _StandardDoctorHomePageState extends State<StandardDoctorHomePage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // TabController for handling the Pending/Accepted/Declined views
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize with 3 tabs
    _tabController = TabController(length: 3, vsync: this);
    _fetchUpcomingAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetches ALL appointments and forces a UI rebuild (Crucial for update)
  Future<void> _fetchUpcomingAppointments() async {
    try {
      final List<dynamic> data = await supabase
          .from('appointments')
          .select()
          .order('appointment_date', ascending: true);

      if (mounted) {
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching appointments.";
          _isLoading = false;
        });
      }
    }
  }

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

  // --- NEW: Function to handle navigation AND refresh/tab change ---
  void _handleAppointmentAction(Map<String, dynamic> appointment) {
    // 1. Navigate to the details page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DoctorAppointmentDetailsPage(appointment: appointment),
      ),
    ).then((result) {
      // 2. The result is the new status string ('confirmed' or 'declined')
      if (result != null && result is String) {
        // Force refresh data
        _fetchUpcomingAppointments().then((_) {
          // 3. Move the tab based on the result
          if (result == 'confirmed') {
            _tabController.animateTo(1); // Index 1 is Accepted
          } else if (result == 'declined') {
            _tabController.animateTo(2); // Index 2 is Declined
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter appointments for the tabs
    final pendingAppointments = _appointments
        .where((appt) => appt['status'] == 'pending')
        .toList();
    final acceptedAppointments = _appointments
        .where((appt) => appt['status'] == 'confirmed')
        .toList();
    final declinedAppointments = _appointments
        .where((appt) => appt['status'] == 'declined')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Portal'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _signOut(context),
          ),
        ],
        // --- ADDED TABS TO THE APP BAR ---
        bottom: TabBar(
          controller: _tabController,
          labelPadding: EdgeInsets.zero,
          tabs: [
            Tab(
              icon: Icon(Icons.access_time_outlined),
              text: 'Pending (${pendingAppointments.length})',
            ),
            Tab(
              icon: Icon(Icons.check_circle_outline),
              text: 'Accepted (${acceptedAppointments.length})',
            ),
            Tab(
              icon: Icon(Icons.cancel_outlined),
              text: 'Declined (${declinedAppointments.length})',
            ),
          ],
        ),
        // ----------------------------------
      ),

      // --- MODIFIED BODY TO USE TAB BAR VIEW ---
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentTabView(pendingAppointments, 'pending'),
          _buildAppointmentTabView(acceptedAppointments, 'confirmed'),
          _buildAppointmentTabView(declinedAppointments, 'declined'),
        ],
      ),

      // --- BOTTOM TASKBAR ---
      floatingActionButton: FloatingActionButton(
        tooltip: 'Refresh Appointments',
        onPressed: _fetchUpcomingAppointments,
        child: const Icon(Icons.refresh),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              tooltip: 'Chat Panel',
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
            ),
            SizedBox(width: 40),
            IconButton(
              tooltip: 'Video Meeting Panel',
              icon: Icon(Icons.videocam_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoCallPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget to build the APPOINTMENT list views (Accepted/Declined/Pending) ---
  Widget _buildAppointmentTabView(
    List<Map<String, dynamic>> filteredAppointments,
    String status,
  ) {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          'Error: $_errorMessage',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Text(
          'No appointments have been booked yet.',
          style: GoogleFonts.lato(fontSize: 18, color: Colors.grey[700]),
        ),
      );
    }

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Text(
          'No ${status.toUpperCase()} appointments found.',
          style: GoogleFonts.lato(fontSize: 18, color: Colors.grey[700]),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = filteredAppointments[index];
        return _DoctorAppointmentCard(
          appointment: appointment,
          // CRITICAL FIX: Pass the item to the handler function
          onTap: () => _handleAppointmentAction(appointment),
        );
      },
    );
  }
}

// --- NEW WIDGET: DOCTOR'S APPOINTMENT CARD ---
class _DoctorAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  // This function now holds the navigation and refresh logic
  final Function() onTap;

  const _DoctorAppointmentCard({
    required this.appointment,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  Color getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'declined':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVideo = appointment['appointment_type'] == 'video-call';
    final IconData iconData = isVideo
        ? Icons.videocam_outlined
        : Icons.calendar_month_outlined;
    final String status = appointment['status'] ?? 'pending';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap, // CRITICAL FIX: Call the handler function
        child: ListTile(
          contentPadding: const EdgeInsets.all(16.0),
          leading: Icon(
            iconData,
            color: isVideo ? Colors.blueAccent : Color(0xFF00796B),
            size: 30,
          ),
          title: Text(
            // Display Patient Name and Reason
            'Patient: ${appointment['contact_name'] ?? 'N/A'} - ${appointment['reason'] ?? 'Check-up'}',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Date: ${appointment['appointment_date']}\nType: ${appointment['appointment_type']}',
            style: GoogleFonts.lato(fontSize: 14, height: 1.4),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.lato(
                color: getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
