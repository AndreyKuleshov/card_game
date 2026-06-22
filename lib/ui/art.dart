import 'package:flutter/material.dart';
import '../engine/kingdom.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CastlePainterView
// ─────────────────────────────────────────────────────────────────────────────

/// A friendly warm-cartoon castle drawn entirely with Canvas.
class CastlePainterView extends StatelessWidget {
  final double size;

  const CastlePainterView({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CastlePainter(),
      ),
    );
  }
}

class _CastlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background sky circle (subtle)
    final bgPaint = Paint()
      ..color = const Color(0xFFB3E5FC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.48, bgPaint);

    // ── Ground ──────────────────────────────────────────────────────────────
    final groundPaint = Paint()..color = const Color(0xFF8BC34A);
    final groundPath = Path()
      ..moveTo(0, h * 0.82)
      ..lineTo(w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, groundPaint);

    // ── Wall ────────────────────────────────────────────────────────────────
    final wallPaint = Paint()..color = const Color(0xFFD7CCC8);
    final wallRect = Rect.fromLTWH(w * 0.22, h * 0.52, w * 0.56, h * 0.30);
    canvas.drawRRect(
      RRect.fromRectAndCorners(wallRect, topLeft: const Radius.circular(2), topRight: const Radius.circular(2)),
      wallPaint,
    );

    // Wall crenellations
    final merlonPaint = Paint()..color = const Color(0xFFBCAAA4);
    final merlonW = w * 0.08;
    final merlonH = h * 0.06;
    for (int i = 0; i < 4; i++) {
      final mx = w * 0.22 + i * (w * 0.56 / 4) + w * 0.02;
      canvas.drawRect(
        Rect.fromLTWH(mx, h * 0.46, merlonW, merlonH),
        merlonPaint,
      );
    }

    // ── Gate ────────────────────────────────────────────────────────────────
    final gatePaint = Paint()..color = const Color(0xFF5D4037);
    final gateRect = Rect.fromLTWH(w * 0.39, h * 0.61, w * 0.22, h * 0.21);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        gateRect,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      gatePaint,
    );

    // Gate details (planks)
    final plankPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.50, h * 0.61),
      Offset(w * 0.50, h * 0.82),
      plankPaint,
    );

    // ── Left tower ──────────────────────────────────────────────────────────
    _drawTower(canvas, size, left: w * 0.10, top: h * 0.34, tw: w * 0.22, th: h * 0.48);

    // ── Right tower ─────────────────────────────────────────────────────────
    _drawTower(canvas, size, left: w * 0.68, top: h * 0.34, tw: w * 0.22, th: h * 0.48);

    // ── Flag on left tower ───────────────────────────────────────────────────
    _drawFlag(canvas, size, poleX: w * 0.21, poleY: h * 0.34);
  }

  void _drawTower(Canvas canvas, Size size, {
    required double left,
    required double top,
    required double tw,
    required double th,
  }) {
    final h = size.height;

    final towerPaint = Paint()..color = const Color(0xFFD7CCC8);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, tw, th),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      towerPaint,
    );

    // Tower crenellations
    final merlonPaint = Paint()..color = const Color(0xFFBCAAA4);
    final mw = tw * 0.28;
    final mh = h * 0.06;
    canvas.drawRect(Rect.fromLTWH(left + tw * 0.08, top - mh, mw, mh), merlonPaint);
    canvas.drawRect(Rect.fromLTWH(left + tw * 0.64, top - mh, mw, mh), merlonPaint);

    // Window slit
    final windowPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(left + tw * 0.35, top + th * 0.25, tw * 0.30, th * 0.28),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      windowPaint,
    );
  }

  void _drawFlag(Canvas canvas, Size size, {
    required double poleX,
    required double poleY,
  }) {
    final h = size.height;
    // Pole
    final polePaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(poleX, poleY),
      Offset(poleX, poleY - h * 0.15),
      polePaint,
    );

    // Flag triangle
    final flagPaint = Paint()..color = const Color(0xFFF57C00);
    final flagPath = Path()
      ..moveTo(poleX, poleY - h * 0.15)
      ..lineTo(poleX + h * 0.09, poleY - h * 0.10)
      ..lineTo(poleX, poleY - h * 0.05)
      ..close();
    canvas.drawPath(flagPath, flagPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// BuildingArt
// ─────────────────────────────────────────────────────────────────────────────

/// Draws building art that visibly changes per level (0 = empty plot → 3 = grand).
class BuildingArt extends StatelessWidget {
  final BuildingType type;
  final int level;
  final double size;

  const BuildingArt({
    super.key,
    required this.type,
    required this.level,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BuildingPainter(type: type, level: level),
      ),
    );
  }
}

class _BuildingPainter extends CustomPainter {
  final BuildingType type;
  final int level;

  const _BuildingPainter({required this.type, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case BuildingType.barracks:
        _paintBarracks(canvas, size);
      case BuildingType.wall:
        _paintWall(canvas, size);
      case BuildingType.mine:
        _paintMine(canvas, size);
    }
  }

  // ── BARRACKS ──────────────────────────────────────────────────────────────
  void _paintBarracks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (level == 0) {
      _paintEmptyPlot(canvas, size);
      return;
    }

    // Ground
    final groundPaint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.80, w, h * 0.20), groundPaint);

    // Building height grows with level
    final buildH = h * (0.25 + level * 0.12);
    final buildTop = h * 0.80 - buildH;

    // Hall body
    final wallPaint = Paint()..color = const Color(0xFFBCAAA4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, buildTop, w * 0.80, buildH),
        const Radius.circular(3),
      ),
      wallPaint,
    );

    // Roof (triangle)
    final roofPaint = Paint()..color = const Color(0xFFF57C00);
    final roofPath = Path()
      ..moveTo(w * 0.05, buildTop)
      ..lineTo(w / 2, buildTop - h * 0.15)
      ..lineTo(w * 0.95, buildTop)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Door
    final doorPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.40, h * 0.80 - h * 0.18, w * 0.20, h * 0.18),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      doorPaint,
    );

    // Crossed arrows symbol
    final arrowPaint = Paint()
      ..color = const Color(0xFFE64A19)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final cx = w * 0.50;
    final cy = buildTop + buildH * 0.35;
    final ar = h * 0.09;
    // First arrow (top-left to bottom-right)
    canvas.drawLine(Offset(cx - ar, cy - ar), Offset(cx + ar, cy + ar), arrowPaint);
    canvas.drawLine(Offset(cx + ar, cy + ar), Offset(cx + ar * 0.4, cy + ar), arrowPaint);
    canvas.drawLine(Offset(cx + ar, cy + ar), Offset(cx + ar, cy + ar * 0.4), arrowPaint);
    // Second arrow (top-right to bottom-left)
    canvas.drawLine(Offset(cx + ar, cy - ar), Offset(cx - ar, cy + ar), arrowPaint);
    canvas.drawLine(Offset(cx - ar, cy + ar), Offset(cx - ar * 0.4, cy + ar), arrowPaint);
    canvas.drawLine(Offset(cx - ar, cy + ar), Offset(cx - ar, cy + ar * 0.4), arrowPaint);

    // Level 3: flag banner
    if (level >= 3) {
      _drawSmallFlag(canvas, size, poleX: w * 0.50, poleBaseY: buildTop, color: const Color(0xFFE64A19));
    }
  }

  // ── WALL ──────────────────────────────────────────────────────────────────
  void _paintWall(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (level == 0) {
      _paintEmptyPlot(canvas, size);
      return;
    }

    // Ground
    final groundPaint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.80, w, h * 0.20), groundPaint);

    // Wall height grows per level: 0.30 / 0.45 / 0.60
    final wallH = h * (0.22 + level * 0.14);
    final wallTop = h * 0.80 - wallH;

    final stonePaint = Paint()..color = const Color(0xFFD7CCC8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, wallTop, w * 0.90, wallH),
        const Radius.circular(2),
      ),
      stonePaint,
    );

    // Stone seam lines
    final seamPaint = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    // Horizontal seams
    for (int row = 1; row <= level; row++) {
      final y = wallTop + wallH * row / (level + 1);
      canvas.drawLine(Offset(w * 0.05, y), Offset(w * 0.95, y), seamPaint);
    }
    // Vertical seam offsets for "brick" look
    canvas.drawLine(Offset(w * 0.35, wallTop), Offset(w * 0.35, h * 0.80), seamPaint);
    canvas.drawLine(Offset(w * 0.65, wallTop), Offset(w * 0.65, h * 0.80), seamPaint);

    // Battlements (crenellations on top)
    final merPaint = Paint()..color = const Color(0xFFBCAAA4);
    final mCount = 3 + level;
    final totalMW = w * 0.90;
    final mW = totalMW / (mCount * 2 - 1);
    final mH = h * 0.07;
    for (int i = 0; i < mCount; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * 0.05 + i * mW * 2, wallTop - mH, mW, mH),
        merPaint,
      );
    }

    // Level 3: flag
    if (level >= 3) {
      _drawSmallFlag(canvas, size, poleX: w * 0.50, poleBaseY: wallTop, color: const Color(0xFF1565C0));
    }
  }

  // ── MINE ──────────────────────────────────────────────────────────────────
  void _paintMine(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (level == 0) {
      _paintEmptyPlot(canvas, size);
      return;
    }

    // Ground
    final groundPaint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.80, w, h * 0.20), groundPaint);

    // Mine entrance arch
    final archPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.25, h * 0.50, w * 0.50, h * 0.30),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
      ),
      archPaint,
    );

    // Dark interior
    final darkPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.31, h * 0.55, w * 0.38, h * 0.25),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      darkPaint,
    );

    // Cart rail lines
    final railPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.20, h * 0.78), Offset(w * 0.50, h * 0.78), railPaint);
    canvas.drawLine(Offset(w * 0.24, h * 0.80), Offset(w * 0.52, h * 0.80), railPaint);

    // Crystals — more per level
    final crystalCount = level; // 1, 2, or 3
    for (int i = 0; i < crystalCount; i++) {
      _drawCrystal(canvas, size, cx: w * (0.20 + i * 0.24), cy: h * 0.38, r: h * 0.07);
    }

    // Level 3: flag
    if (level >= 3) {
      _drawSmallFlag(canvas, size, poleX: w * 0.80, poleBaseY: h * 0.50, color: const Color(0xFF388E3C));
    }
  }

  // ── EMPTY PLOT ────────────────────────────────────────────────────────────
  void _paintEmptyPlot(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground
    final groundPaint = Paint()..color = const Color(0xFFDCE775);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), groundPaint);

    // Dashed outline of a future plot
    final dashPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashLen = 4.0;
    const gapLen = 3.0;
    final plotRect = Rect.fromLTWH(w * 0.10, h * 0.30, w * 0.80, h * 0.45);
    _drawDashedRect(canvas, plotRect, dashPaint, dashLen, gapLen);

    // "?" marker in the centre
    final textSpan = TextSpan(
      text: '?',
      style: TextStyle(
        color: const Color(0xFF9E9E9E),
        fontSize: w * 0.32,
        fontWeight: FontWeight.w700,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h * 0.40 - tp.height / 2));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _drawCrystal(Canvas canvas, Size size, {
    required double cx,
    required double cy,
    required double r,
  }) {
    final crystalPaint = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF80D8FF),
        const Color(0xFF0288D1),
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.6, cy - r * 0.2)
      ..lineTo(cx + r * 0.6, cy + r * 0.5)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.6, cy + r * 0.5)
      ..lineTo(cx - r * 0.6, cy - r * 0.2)
      ..close();
    canvas.drawPath(path, crystalPaint);

    // Shine
    final shinePaint = Paint()
      ..color = Colors.white.withAlpha(140)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - r * 0.2, cy - r * 0.7), Offset(cx + r * 0.1, cy - r * 0.3), shinePaint);
  }

  void _drawSmallFlag(Canvas canvas, Size size, {
    required double poleX,
    required double poleBaseY,
    required Color color,
  }) {
    final h = size.height;
    final poleH = h * 0.18;
    final polePaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(poleX, poleBaseY),
      Offset(poleX, poleBaseY - poleH),
      polePaint,
    );

    final flagPaint = Paint()..color = color;
    final flagPath = Path()
      ..moveTo(poleX, poleBaseY - poleH)
      ..lineTo(poleX + h * 0.09, poleBaseY - poleH + h * 0.05)
      ..lineTo(poleX, poleBaseY - poleH + h * 0.10)
      ..close();
    canvas.drawPath(flagPath, flagPaint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, double dashLen, double gapLen) {
    final path = Path()..addRect(rect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BuildingPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.level != level;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DuelistPainterView
// ─────────────────────────────────────────────────────────────────────────────

/// Stylized seated duelist character. [isOpponent] true = greenish villain,
/// false = warm-skinned hero.
class DuelistPainterView extends StatelessWidget {
  final bool isOpponent;
  final double size;

  const DuelistPainterView({super.key, required this.isOpponent, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DuelistPainter(isOpponent: isOpponent),
      ),
    );
  }
}

class _DuelistPainter extends CustomPainter {
  final bool isOpponent;

  const _DuelistPainter({required this.isOpponent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final skinColor = isOpponent ? const Color(0xFF9CCC65) : const Color(0xFFFFCC80);
    final bodyColor = isOpponent ? const Color(0xFF558B2F) : const Color(0xFF1565C0);
    final hairColor = isOpponent ? const Color(0xFF33691E) : const Color(0xFF5D4037);

    // ── Body (torso) ─────────────────────────────────────────────────────────
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.52, w * 0.50, h * 0.36),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // ── Shoulders ────────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromLTWH(w * 0.12, h * 0.50, w * 0.22, h * 0.16),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.66, h * 0.50, w * 0.22, h * 0.16),
      bodyPaint,
    );

    // ── Head ─────────────────────────────────────────────────────────────────
    final headPaint = Paint()..color = skinColor;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.28, h * 0.10, w * 0.44, h * 0.42),
      headPaint,
    );

    // ── Hair ─────────────────────────────────────────────────────────────────
    final hairPaint = Paint()..color = hairColor;
    if (isOpponent) {
      // Spiky villain hair
      final hairPath = Path();
      hairPath.moveTo(w * 0.28, h * 0.28);
      hairPath.lineTo(w * 0.22, h * 0.10);
      hairPath.lineTo(w * 0.35, h * 0.18);
      hairPath.lineTo(w * 0.40, h * 0.08);
      hairPath.lineTo(w * 0.50, h * 0.18);
      hairPath.lineTo(w * 0.55, h * 0.06);
      hairPath.lineTo(w * 0.65, h * 0.18);
      hairPath.lineTo(w * 0.72, h * 0.28);
      hairPath.close();
      canvas.drawPath(hairPath, hairPaint);
    } else {
      // Rounded hero hair
      canvas.drawOval(
        Rect.fromLTWH(w * 0.27, h * 0.08, w * 0.46, h * 0.24),
        hairPaint,
      );
    }

    // ── Eyes ─────────────────────────────────────────────────────────────────
    final eyePaint = Paint()..color = Colors.black87;
    final eyeWhitePaint = Paint()..color = Colors.white;

    // Left eye
    canvas.drawOval(Rect.fromLTWH(w * 0.35, h * 0.26, w * 0.12, h * 0.10), eyeWhitePaint);
    canvas.drawCircle(Offset(w * 0.41, h * 0.31), w * 0.04, eyePaint);

    // Right eye
    canvas.drawOval(Rect.fromLTWH(w * 0.53, h * 0.26, w * 0.12, h * 0.10), eyeWhitePaint);
    canvas.drawCircle(Offset(w * 0.59, h * 0.31), w * 0.04, eyePaint);

    // ── Mouth ─────────────────────────────────────────────────────────────────
    final mouthPaint = Paint()
      ..color = isOpponent ? const Color(0xFF8D6E63) : const Color(0xFFE64A19)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    if (isOpponent) {
      // Grin (wider upward curve)
      final grinPath = Path()
        ..moveTo(w * 0.36, h * 0.44)
        ..quadraticBezierTo(w * 0.50, h * 0.54, w * 0.64, h * 0.44);
      canvas.drawPath(grinPath, mouthPaint);
    } else {
      // Friendly smile
      final smilePath = Path()
        ..moveTo(w * 0.38, h * 0.43)
        ..quadraticBezierTo(w * 0.50, h * 0.51, w * 0.62, h * 0.43);
      canvas.drawPath(smilePath, mouthPaint);
    }

    // ── Villain extra: small horns ────────────────────────────────────────────
    if (isOpponent) {
      final hornPaint = Paint()..color = const Color(0xFF33691E);
      // Left horn
      final lHorn = Path()
        ..moveTo(w * 0.34, h * 0.16)
        ..lineTo(w * 0.28, h * 0.04)
        ..lineTo(w * 0.38, h * 0.14)
        ..close();
      canvas.drawPath(lHorn, hornPaint);
      // Right horn
      final rHorn = Path()
        ..moveTo(w * 0.66, h * 0.16)
        ..lineTo(w * 0.72, h * 0.04)
        ..lineTo(w * 0.62, h * 0.14)
        ..close();
      canvas.drawPath(rHorn, hornPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DuelistPainter oldDelegate) {
    return oldDelegate.isOpponent != isOpponent;
  }
}
