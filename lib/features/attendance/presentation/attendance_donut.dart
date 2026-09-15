import 'package:flutter/material.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';

class AttendanceDonut extends StatelessWidget {
  const AttendanceDonut({
    super.key,
    required this.percent,
    this.size = 96,
  });

  final double percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(percent: percent / 100),
          ),
          Text(
            '${percent.round()}%',
            style: AppTextStyles.h3.copyWith(fontSize: size * 0.19, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2832, false, track);

    final progress = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    const start = -1.5708; // -90deg
    canvas.drawArc(rect, start, 6.2832 * percent.clamp(0, 1), false, progress);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.percent != percent;
}
