// lib/screens/patient_home_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Required for launching external apps

import 'package:relief_dental_app/main.dart'; // For supabase
import 'package:relief_dental_app/screens/login_page.dart';
import 'package:relief_dental_app/screens/appointment_booking_page.dart';
import 'package:relief_dental_app/screens/profile_pages.dart';
import 'package:relief_dental_app/screens/chat_page.dart';
import 'package:relief_dental_app/screens/video_call_page.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({Key? key}) : super(key: key);

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  // Fetches appointments belonging ONLY to the logged-in user
  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final List<dynamic> data = await supabase
          .from('appointments')
          .select()
          .eq('patient_id', user.id) // IMPORTANT: Filters by user ID
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
          _errorMessage = error.toString();
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

  void _navigateToBooking(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentBookingPage(appointmentType: type),
      ),
    ).then((_) {
      _fetchAppointments(); // Refresh on return
    });
  }

  void _onProfileMenuSelected(String choice) {
    switch (choice) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyProfilePage()),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
      case 'bills':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyBillsPage()),
        );
        break;
      case 'language':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LanguagePage()),
        );
        break;
      case 'help':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpPage()),
        );
        break;
      case 'logout':
        _signOut(context);
        break;
    }
  }

  // --- Reschedule action for declined appointments ---
  void _reschedule(Map<String, dynamic> oldAppointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the data to a new instance of the booking page
        builder: (context) => AppointmentBookingPage(
          appointmentType: oldAppointment['appointment_type'] ?? 'in-person',
          // Pass old data to pre-fill the form
          initialName: oldAppointment['contact_name'],
          initialEmail: oldAppointment['contact_email'],
          initialPhone: oldAppointment['contact_phone'],
          initialReason: oldAppointment['reason'],
        ),
      ),
    ).then((_) {
      // Refresh list after new request is submitted
      _fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Home'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onProfileMenuSelected,
            icon: const Icon(Icons.person_outline),
            itemBuilder: (BuildContext context) {
              return [
                // ... (Profile menu items)
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 8),
                      Text('My Profile'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'bills',
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 8),
                      Text('My Bills'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'language',
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 8),
                      Text('Language'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 8),
                      Text('Help'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red[600])),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Appointments',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAppointmentsList(),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Book In-Person Appointment',
        onPressed: () => _navigateToBooking('in-person'),
        child: const Icon(Icons.book_online),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              tooltip: 'Chat with Doctor',
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
              tooltip: 'Schedule Video Meeting',
              icon: Icon(Icons.videocam_outlined),
              onPressed: () => _navigateToBooking('video-call'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
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
          'You have no appointments. Tap the green button to book one!',
          style: GoogleFonts.lato(fontSize: 18, color: Colors.grey[700]),
        ),
      );
    }

    return ListView.builder(
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onReschedule: () => _reschedule(appointment),
        );
      },
    );
  }
}

// --- NEW WIDGET: PATIENT'S APPOINTMENT CARD (Status Display & Reschedule Button) ---
class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Function() onReschedule;

  const _AppointmentCard({
    Key? key,
    required this.appointment,
    required this.onReschedule,
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
    final bool isConfirmed = appointment['status'] == 'confirmed';
    final String status = appointment['status'] ?? 'pending';
    final Color statusColor = getStatusColor(status);
    final String? declineReason = appointment['rejection_reason'];
    final String? rescheduleMessage = appointment['reschedule_message'];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        // HEADER
        leading: Icon(
          isVideo ? Icons.videocam_outlined : Icons.calendar_month_outlined,
          color: statusColor,
          size: 30,
        ),
        title: Text(
          appointment['reason'] ?? 'Appointment',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Date: ${appointment['appointment_date']}\nStatus: ${status.toUpperCase()}',
          style: GoogleFonts.lato(
            fontSize: 14,
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.keyboard_arrow_down),

        // --- EXPANDED BODY ---
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. CONFIRMED IN-PERSON APPOINTMENT DETAILS (CLINIC CARD)
                if (isConfirmed && !isVideo) // Check 2: Confirmed AND not video
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child:
                        _ClinicLocationCard(), // <-- The card you want to see
                  ),

                // 2. Decline/Action Message
                if (status == 'declined')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Doctor Message:',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                if (declineReason != null)
                  Text('Reason: ${declineReason}', style: GoogleFonts.lato()),

                if (rescheduleMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Reschedule Note: ${rescheduleMessage}',
                      style: GoogleFonts.lato(fontStyle: FontStyle.italic),
                    ),
                  ),

                if (status == 'declined') const SizedBox(height: 16),

                // 3. RESCHEDULE BUTTON (ONLY SHOWN WHEN DECLINED)
                if (status == 'declined')
                  ElevatedButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Reschedule This Appointment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),

                // 4. Meeting Link Button (For Confirmed Video Calls)
                if (isConfirmed && isVideo)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final meetLink = appointment['meeting_link'];
                      if (meetLink != null) {
                        final Uri uri = Uri.parse(meetLink);
                        // Use externalApplication mode to prioritize opening the native app
                        if (await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                          print('Launching Meet Link: $meetLink');
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open video link.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Meeting link not yet provided by the doctor.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.video_call),
                    label: const Text('Join Video Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW WIDGET: CLINIC LOCATION CARD (Hardcoded Details) ---
class _ClinicLocationCard extends StatelessWidget {
  const _ClinicLocationCard({Key? key}) : super(key: key);

  // Hardcoded Clinic Address
  final String clinicAddress =
      '26F7+PC6, West Saidapet, Saidapet, Chennai, Tamil Nadu 600015';

  // Function to launch the native Google Maps app with the address
  Future<void> _launchMapsUrl(BuildContext context) async {
    // We use the Google Maps query format which is reliable for launching native app
    // The specific URL requested (https://maps.app.goo.gl/8tbpNdxjmqsiiLqq8)
    final String googleMapsUrl = 'https://maps.app.goo.gl/8tbpNdxjmqsiiLqq8';

    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      // Use externalApplication mode to prioritize opening the native Maps app
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback for devices that cannot open the URL
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not launch Google Maps. Please check your app permissions.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.lightGreen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Clinic Location',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen,
            ),
          ),
          const Divider(height: 10, thickness: 1),
          _buildDetailRow(
            Icons.local_hospital,
            'Relief Dental Care',
            'Your appointment is here.',
          ),
          _buildDetailRow(Icons.location_on, 'Address:', clinicAddress),
          _buildDetailRow(Icons.phone, 'Contact:', '+91 98841 62994'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _launchMapsUrl(context),
            icon: const Icon(Icons.directions, color: Colors.white),
            label: const Text(
              'Get Directions',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lato(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
