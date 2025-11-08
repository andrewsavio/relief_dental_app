import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        // The AppBar color will be set automatically by the theme in main.dart
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
