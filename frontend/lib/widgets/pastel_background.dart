import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Background khas MyNotes: Putih krem hangat dengan ornamen abstrak pastel
/// yang lembut dan tidak mengganggu keterbacaan konten.
class PastelBackground extends StatelessWidget {
  final Widget child;
  final bool showOrnaments;

  const PastelBackground({
    super.key,
    required this.child,
    this.showOrnaments = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.creamBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showOrnaments)
            const IgnorePointer(
              child: CustomPaint(
                painter: _PastelOrnamentPainter(),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _PastelOrnamentPainter extends CustomPainter {
  const _PastelOrnamentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ornamen Mint Green organik di sudut kanan atas
    final mintPaint = Paint()
      ..color = AppColors.mintGreen.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    final topPath = Path()
      ..moveTo(size.width * 0.58, 0)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.12,
        size.width * 0.76,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.19,
        size.width,
        size.height * 0.11,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(topPath, mintPaint);

    // 2. Ornamen Lavender lembut di sisi kiri atas
    final lavenderPaint = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(-size.width * 0.08, size.height * 0.14),
      size.width * 0.32,
      lavenderPaint,
    );

    // 3. Ornamen Yellow pastel di sudut kiri bawah
    final yellowPaint = Paint()
      ..color = AppColors.yellow.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final bottomLeftPath = Path()
      ..moveTo(0, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.82,
        size.width * 0.36,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bottomLeftPath, yellowPaint);

    // 4. Aksen Pink lembut di kanan bawah
    final pinkPaint = Paint()
      ..color = AppColors.pink.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.88),
      size.width * 0.24,
      pinkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
