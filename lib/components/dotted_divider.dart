import 'package:flutter/material.dart';

class DottedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const DottedDivider(
      {super.key, this.height = 1.0, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: CustomPaint(
        painter: _DottedLinePainter(color),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5.0, dashSpace = 5.0, startX = 0.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    while (startX < size.width) {
      canvas.drawLine(
          Offset(startX, 0.0), Offset(startX + dashWidth, 0.0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
