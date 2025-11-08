import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoCallPage extends StatelessWidget {
  const VideoCallPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.videocam_outlined),
            SizedBox(width: 8),
            Text('Video Meeting Panel'),
          ],
        ),
        // Color is handled by the theme
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.video_camera_back,
                size: 60,
                color: Theme.of(context).primaryColor, // Use theme color
              ),
              const SizedBox(height: 24),

              Text(
                'Telehealth Integration Zone',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'This page will soon host the live video call feature. '
                'When ready, integrate an SDK (like ZEGOCLOUD or Agora) here '
                'to start the call using the confirmed meeting link.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // --- Next Step Button Placeholder ---
              ElevatedButton.icon(
                onPressed: () {
                  // This is where you would place logic to check for an ongoing call
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Future Feature: Check for Active Calls!'),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check for Scheduled Calls'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  backgroundColor: Color(0xFF00796B), // dentalGreen
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
