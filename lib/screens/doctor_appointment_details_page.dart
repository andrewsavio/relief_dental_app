// lib/screens/doctor_appointment_details_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:relief_dental_app/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

class DoctorAppointmentDetailsPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const DoctorAppointmentDetailsPage({Key? key, required this.appointment})
    : super(key: key);

  @override
  State<DoctorAppointmentDetailsPage> createState() =>
      _DoctorAppointmentDetailsPageState();
}

class _DoctorAppointmentDetailsPageState
    extends State<DoctorAppointmentDetailsPage> {
  final _meetingLinkController = TextEditingController();
  // --- NEW CONTROLLER ---
  final _rescheduleMessageController = TextEditingController();
  // ----------------------
  String? _selectedReason;
  bool _isSubmitting = false;

  String? _lottieFilePath;

  List<Map<String, dynamic>> _rejectionReasons = [];
  bool _declineIntent = false;

  @override
  void initState() {
    super.initState();
    _fetchRejectionReasons();
    _meetingLinkController.text = widget.appointment['meeting_link'] ?? '';
    // Pre-fill reschedule message if it already exists
    _rescheduleMessageController.text =
        widget.appointment['reschedule_message'] ?? '';
  }

  @override
  void dispose() {
    _meetingLinkController.dispose();
    _rescheduleMessageController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _fetchRejectionReasons() async {
    try {
      final List<dynamic> data = await supabase
          .from('rejection_reasons')
          .select('reason');

      setState(() {
        _rejectionReasons = List<Map<String, dynamic>>.from(data);
        if (_rejectionReasons.isNotEmpty && _selectedReason == null) {
          _selectedReason = _rejectionReasons.first['reason'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading reasons.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Core Approval Logic (MODIFIED) ---
  Future<void> _updateAppointment(String newStatus) async {
    // 1. Validation Checks
    if (newStatus == 'declined' && _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for declining.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (newStatus == 'confirmed' &&
        widget.appointment['appointment_type'] == 'video-call' &&
        _meetingLinkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a meeting link to confirm a video call.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appointmentId = widget.appointment['id'];

      final updates = {
        'status': newStatus,
        'meeting_link': newStatus == 'confirmed'
            ? _meetingLinkController.text
            : null,
        'rejection_reason': newStatus == 'declined' ? _selectedReason : null,
        // --- NEW: Save the custom reschedule message ---
        'reschedule_message': newStatus == 'declined'
            ? _rescheduleMessageController.text
            : null,
      };

      await supabase
          .from('appointments')
          .update(updates)
          .eq('id', appointmentId);

      if (mounted) {
        // --- TRIGGER ANIMATION ON SUCCESS ---
        setState(() {
          _lottieFilePath = newStatus == 'confirmed'
              ? 'assets/animations/success.json'
              : 'assets/animations/Rejected.json';
        });

        await Future.delayed(const Duration(milliseconds: 2000));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment $newStatus!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pass the status back to the dashboard for tab navigation
        Navigator.pop(context, newStatus);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  // --- UI Builders ---
  Widget _buildStatusSection() {
    final bool isVideo = widget.appointment['appointment_type'] == 'video-call';
    final bool isConfirmed = widget.appointment['status'] == 'confirmed';
    final bool isDeclined = widget.appointment['status'] == 'declined';

    // Display current final status
    if (isConfirmed || isDeclined) {
      return Center(
        child: Text(
          isConfirmed ? 'STATUS: CONFIRMED' : 'STATUS: DECLINED',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isConfirmed ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      );
    }

    // --- Action View (Pending) ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- REJECTION REASON DROPDOWN (Shown ONLY when DECLINE intent is active) ---
        if (_declineIntent)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reason for Decline:',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Reason',
                  border: OutlineInputBorder(),
                ),
                value: _selectedReason,
                items: _rejectionReasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason['reason'],
                    child: Text(reason['reason']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReason = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Reason required to decline' : null,
              ),
              SizedBox(height: 16),

              // --- NEW RESCHEDULE MESSAGE FIELD ---
              Text(
                'Reschedule/Custom Message:',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _rescheduleMessageController,
                decoration: const InputDecoration(
                  hintText: 'Suggested dates or next steps for patient.',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
              ),
              // ------------------------------------
              SizedBox(height: 20),
            ],
          ),

        // VIDEO LINK FIELD (Only for video calls, hidden during decline intent)
        if (isVideo && !_declineIntent)
          TextFormField(
            controller: _meetingLinkController,
            decoration: const InputDecoration(
              labelText: 'Google Meet Link (required for confirmation)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),

        SizedBox(height: isVideo && !_declineIntent ? 20 : 0),

        // --- BUTTONS ---
        Row(
          children: [
            // DECLINE BUTTON (Red)
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_declineIntent) {
                          _updateAppointment('declined');
                        } else {
                          setState(() => _declineIntent = true);
                        }
                      },
                child: Text(
                  _declineIntent ? 'CONFIRM DECLINE' : 'DECLINE',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            SizedBox(width: 10),
            // ACCEPT BUTTON (Green)
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(
                          () => _declineIntent = false,
                        ); // Clear any reject intent
                        _updateAppointment('confirmed');
                      },
                child: Text(
                  'ACCEPT',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent.shade400,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),

        // Button to cancel decline intent
        if (_declineIntent)
          TextButton(
            onPressed: () {
              setState(() {
                _declineIntent = false;
                _selectedReason = _rejectionReasons.isNotEmpty
                    ? _rejectionReasons.first['reason']
                    : null;
              });
            },
            child: Text(
              'Cancel Decline',
              style: GoogleFonts.lato(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lottieFilePath != null) {
      final bool isSuccess =
          _lottieFilePath == 'assets/animations/success.json';
      final Color backgroundColor = isSuccess
          ? Colors.lightGreen.shade200
          : Colors.red.shade200;

      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Lottie.asset(
            _lottieFilePath!,
            repeat: false,
            width: 300,
            height: 300,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Manage Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.appointment['reason'] ?? 'Appointment Detail',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 30),

            // USER DETAILS
            _DetailTile(
              icon: Icons.person,
              title: 'Patient Name',
              content: widget.appointment['contact_name'],
            ),
            _DetailTile(
              icon: Icons.email,
              title: 'Email',
              content: widget.appointment['contact_email'],
            ),
            _DetailTile(
              icon: Icons.phone,
              title: 'Phone',
              content: widget.appointment['contact_phone'],
            ),
            _DetailTile(
              icon: Icons.calendar_today,
              title: 'Date',
              content: widget.appointment['appointment_date'],
            ),
            _DetailTile(
              icon: widget.appointment['appointment_type'] == 'video-call'
                  ? Icons.videocam
                  : Icons.home,
              title: 'Type',
              content: widget.appointment['appointment_type'] ?? 'in-person',
            ),

            Divider(height: 30),

            _buildStatusSection(),
          ],
        ),
      ),
    );
  }
}

// Helper widget for detailed view
class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
