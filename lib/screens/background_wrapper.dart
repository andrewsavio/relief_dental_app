// lib/widgets/background_wrapper.dart

import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Full-Screen Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/app_background.jpg', // <-- Replace with your file name
            fit: BoxFit.cover, // Ensure it covers the whole screen
          ),
        ),
        // 2. The Child Widget (Your entire app content)
        child,
      ],
    );
  }
}
