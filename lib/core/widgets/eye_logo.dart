import 'package:flutter/material.dart';

class EyeLogo extends StatelessWidget {
  const EyeLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(Icons.remove_red_eye_rounded, color: Colors.tealAccent.shade100, size: size * 0.46),
    );
  }
}
