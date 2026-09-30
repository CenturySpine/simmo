import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The Simmo logo: a white house on the brand gradient tile. The same
/// drawing produces the PWA icons (tool/generate_icons.dart).
class SimmoLogo extends StatelessWidget {
  const SimmoLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Simmo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: brandGradient,
          borderRadius: BorderRadius.circular(size * 0.26),
        ),
        padding: EdgeInsets.all(size * 0.18),
        child: CustomPaint(painter: SimmoLogoGlyphPainter()),
      ),
    );
  }
}

const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.brandStart, AppColors.brandEnd],
);

/// The house glyph alone, drawn on a 100x100 grid scaled to [Size].
class SimmoLogoGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final stroke = Paint()
      ..color = AppColors.onPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(10, 48)
        ..lineTo(50, 12)
        ..lineTo(90, 48),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, 50)
        ..lineTo(24, 88)
        ..lineTo(76, 88)
        ..lineTo(76, 50),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(42, 62, 58, 88, const Radius.circular(3)),
      Paint()..color = AppColors.onPrimary,
    );
  }

  @override
  bool shouldRepaint(SimmoLogoGlyphPainter oldDelegate) => false;
}
