// lib/screens/appointment_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailsPage({Key? key, required this.appointment})
    : super(key: key);

  Future<void> _launchGoogleMeet(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch Google Meet.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String reason = appointment['reason'] ?? 'No Reason';
    final String date = appointment['appointment_date'] ?? 'No Date';
    final String status = appointment['status'] ?? 'pending';
    final String? meetLink = appointment['meeting_link'];
    final bool isVideo = appointment['appointment_type'] == 'video-call';
    final Color statusColor = status == 'confirmed'
        ? Colors.green.shade700
        : Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(title: Text('Meeting Details')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason,
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              title: 'Date',
              content: date,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.info_outline,
              title: 'Status',
              contentWidget: Text(
                status.toUpperCase(),
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (isVideo)
              ElevatedButton.icon(
                icon: const Icon(Icons.video_call),
                label: const Text('Join Google Meet'),
                onPressed: (meetLink != null && meetLink.isNotEmpty)
                    ? () => _launchGoogleMeet(meetLink, context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFFA5D6A7) // Light green for dark mode
                      : Color(0xFF00796B), // Dark green for light mode
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors
                            .black // Dark text for dark mode
                      : Colors.white, // Light text for light mode
                  minimumSize: Size(double.infinity, 50),
                  textStyle: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isVideo && (meetLink == null || meetLink.isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: Text(
                    'The Google Meet link will appear once your appointment is confirmed by the doctor.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? content;
  final Widget? contentWidget;

  const _DetailRow({
    Key? key,
    required this.icon,
    required this.title,
    this.content,
    this.contentWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.lato(fontSize: 16)),
            const SizedBox(height: 4),
            contentWidget ??
                Text(
                  content ?? '',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

// You can put this in lib/screens/chat_page.dart
class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 8),
            Text('Chat with Doctor'),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Chat feature will go here.',
          style: GoogleFonts.lato(fontSize: 18),
        ),
      ),
    );
  }
}
