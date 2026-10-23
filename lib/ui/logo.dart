import 'package:flutter/material.dart';

import '../theme.dart';

/// The Verto mark: two overlapping speech bubbles on a purple tile.
class VertoLogo extends StatelessWidget {
  const VertoLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 140;
    Offset o(double x, double y) => Offset(x * k, y * k);
    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x * k, y * k, w * k, h * k), Radius.circular(r * k));

    canvas.drawRRect(rr(0, 0, 140, 140, 32), Paint()..color = kPrimary);

    final soft = Paint()..color = kSoft;
    canvas.drawRRect(rr(22, 26, 62, 46, 12), soft);
    canvas.drawPath(
      Path()
        ..moveTo(o(34, 72).dx, o(34, 72).dy)
        ..lineTo(o(34, 88).dx, o(34, 88).dy)
        ..lineTo(o(50, 72).dx, o(50, 72).dy)
        ..close(),
      soft,
    );

    final mid = Paint()..color = kMid;
    canvas.drawRRect(rr(56, 54, 62, 46, 12), mid);
    canvas.drawPath(
      Path()
        ..moveTo(o(106, 100).dx, o(106, 100).dy)
        ..lineTo(o(106, 116).dx, o(106, 116).dy)
        ..lineTo(o(90, 100).dx, o(90, 100).dy)
        ..close(),
      mid,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
