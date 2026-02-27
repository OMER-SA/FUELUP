import 'package:flutter/material.dart';
import 'package:diet_app/utilities/constants.dart';
import 'dart:math';

class BmiGuage extends StatelessWidget {
  final double bmi;
  const BmiGuage({super.key, required this.bmi});

  @override
  Widget build(BuildContext context) {
    final DefaultColors defaultColors = DefaultColors();

    String getBmiStatus(double bmi) {
      if (bmi <= 18.4) return "Underweight";
      if (bmi <= 24.9) return "Normal";
      if (bmi <= 29.9) return "Overweight";
      return "Obese";
    }

    Color getBmiColor(double bmi) {
      if (bmi <= 18.4) return Colors.blue;
      if (bmi <= 24.9) return defaultColors.primaryColor;
      if (bmi <= 29.9) return Colors.orange;
      return defaultColors.redColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BMI',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: defaultColors.primaryColor),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: getBmiColor(bmi),
                  ),
                ),
                Text(
                  getBmiStatus(bmi),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: getBmiColor(bmi),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 100,
              width: 100,
              child: CustomPaint(
                painter: BmiArcPainter(bmi: bmi, color: getBmiColor(bmi)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBmiCategory('Underweight', '< 18.5', Colors.blue),
            _buildBmiCategory('Normal', '18.5 - 24.9', Colors.green),
            _buildBmiCategory('Overweight', '25 - 29.9', Colors.orange),
            _buildBmiCategory('Obese', '≥ 30', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildBmiCategory(String label, String range, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          range,
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

class BmiArcPainter extends CustomPainter {
  final double bmi;
  final Color color;

  BmiArcPainter({required this.bmi, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.8;
    const startAngle = -pi;
    final sweepAngle = (bmi / 40) * pi;
    const int thickness = 20;

    // Draw main arc
    final mainPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness.toDouble() 
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      pi,
      false,
      mainPaint,
    );

    // Draw BMI indicator
    final indicatorPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
        stops: [0.0, 0.33, 0.66, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness.toDouble()
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
