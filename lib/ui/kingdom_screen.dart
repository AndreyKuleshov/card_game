import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';
import '../state/providers.dart';
import 'art.dart';
import 'theme.dart';
import 'widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KingdomScreen
// ─────────────────────────────────────────────────────────────────────────────

class KingdomScreen extends ConsumerStatefulWidget {
  const KingdomScreen({super.key});

  @override
  ConsumerState<KingdomScreen> createState() => _KingdomScreenState();
}

class _KingdomScreenState extends ConsumerState<KingdomScreen> {
  BuildingType _selected = BuildingType.fireForge;

  static const _titles = {
    BuildingType.fireForge: 'Зажигалка',
    BuildingType.waterWell: 'Полторашка',
    BuildingType.natureGrove: 'Травка',
    BuildingType.wall: 'Стена',
    BuildingType.mine: 'Шахта',
  };

  // Level-independent purpose, shown in the panel even when not built yet.
  static const _descriptions = {
    BuildingType.fireForge: 'Усиливает 🔥 огненные карты в бою',
    BuildingType.waterWell: 'Усиливает 💧 водяные карты в бою',
    BuildingType.natureGrove: 'Усиливает 🌿 карты природы в бою',
    BuildingType.wall: 'Повышает прочность замка — больше ХП',
    BuildingType.mine: 'Приносит кристаллы 💎 за победу в дуэли',
  };

  String _effect(BuildingType type, Kingdom k) {
    final level = k.levelOf(type);
    if (level == 0) return 'Не построено';
    switch (type) {
      case BuildingType.fireForge:
        return '+$level к 🔥 стихии';
      case BuildingType.waterWell:
        return '+$level к 💧 стихии';
      case BuildingType.natureGrove:
        return '+$level к 🌿 стихии';
      case BuildingType.wall:
        return '+${k.wallHpBonus} ХП замка';
      case BuildingType.mine:
        return '+${k.mineCrystalsPerWin} 💎 за победу';
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(saveStateProvider);
    final controller = ref.read(saveStateProvider.notifier);
    final k = save.kingdom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Королевство'),
        actions: [
          CrystalChip(amount: save.crystals),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GameColors.backgroundStops,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availW = constraints.maxWidth;
              final availH = constraints.maxHeight;

              // Scene: wider cap (600px), taller height share for visual focus.
              final sceneW = availW.clamp(0.0, 600.0);
              // On tall phones give it 62%, clamp to [220, 400].
              final sceneH = (availH * 0.62).clamp(220.0, 400.0);

              return Column(
                children: [
                  // ── Village scene ──────────────────────────────────────────
                  SizedBox(
                    width: availW,
                    height: sceneH,
                    child: Center(
                      child: SizedBox(
                        width: sceneW,
                        height: sceneH,
                        child: _VillageScene(
                          kingdom: k,
                          selected: _selected,
                          onSelect: (t) => setState(() => _selected = t),
                          titles: _titles,
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom panel ───────────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _UpgradePanel(
                            type: _selected,
                            title: _titles[_selected]!,
                            description: _descriptions[_selected]!,
                            level: k.levelOf(_selected),
                            effect: _effect(_selected, k),
                            crystals: save.crystals,
                            onUpgrade: () => controller.tryUpgrade(_selected),
                          ),
                          if (k.fireLevel >= 3) ...[
                            const SizedBox(height: 8),
                            _CraftSection(save: save, controller: controller),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VillageScene
// ─────────────────────────────────────────────────────────────────────────────

class _VillageScene extends StatelessWidget {
  final Kingdom kingdom;
  final BuildingType selected;
  final ValueChanged<BuildingType> onSelect;
  final Map<BuildingType, String> titles;

  const _VillageScene({
    required this.kingdom,
    required this.selected,
    required this.onSelect,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: _MeadowPainter(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Castle centred slightly above middle — a little bigger now.
            final castleSize = (w * 0.26).clamp(72.0, 130.0);

            // Building widget size — scales with scene width.
            final bldSize = (w * 0.15).clamp(44.0, 70.0);

            // Positions for 5 buildings — no overlap, fits 360–600px wide.
            // Front row: fireForge(left), natureGrove(center), waterWell(right)
            // Sides: wall(far-left), mine(far-right)
            final positions = {
              BuildingType.wall: Offset(w * 0.01, h * 0.38),
              BuildingType.fireForge: Offset(w * 0.16, h * 0.53),
              BuildingType.natureGrove: Offset(w * 0.41, h * 0.57),
              BuildingType.waterWell: Offset(w * 0.64, h * 0.53),
              BuildingType.mine: Offset(w * 0.80, h * 0.38),
            };

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Castle at centre/back.
                Positioned(
                  left: w / 2 - castleSize / 2,
                  top: h * 0.04,
                  child: CastlePainterView(size: castleSize),
                ),

                // Buildings — render in z-order (back first).
                for (final type in [
                  BuildingType.wall,
                  BuildingType.mine,
                  BuildingType.fireForge,
                  BuildingType.waterWell,
                  BuildingType.natureGrove,
                ])
                  _PositionedBuilding(
                    type: type,
                    level: kingdom.levelOf(type),
                    title: titles[type]!,
                    size: bldSize,
                    offset: positions[type]!,
                    isSelected: selected == type,
                    onTap: () => onSelect(type),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MeadowPainter — enriched background with env detail
// ─────────────────────────────────────────────────────────────────────────────

class _MeadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Sky gradient ──────────────────────────────────────────────────────────
    final skyRect = Rect.fromLTWH(0, 0, w, h * 0.52);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7BBFED), Color(0xFFB8DEFA)],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Fluffy cloud blobs (deterministic positions)
    _drawCloud(canvas, w * 0.12, h * 0.09, w * 0.14);
    _drawCloud(canvas, w * 0.55, h * 0.06, w * 0.11);
    _drawCloud(canvas, w * 0.80, h * 0.12, w * 0.09);

    // ── Meadow ────────────────────────────────────────────────────────────────
    final meadowRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, h * 0.34, w, h * 0.66),
      topLeft: const Radius.circular(36),
      topRight: const Radius.circular(36),
    );
    final meadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8BC34A), Color(0xFF558B2F)],
      ).createShader(Rect.fromLTWH(0, h * 0.34, w, h * 0.66));
    canvas.drawRRect(meadowRect, meadowPaint);

    // Subtle ground shading strip at horizon
    final horizonPaint = Paint()
      ..color = const Color(0xFF6AAF2E).withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.34, w, h * 0.08), horizonPaint);

    // ── Dirt road network ─────────────────────────────────────────────────────
    final castleCX = w * 0.50;
    final castleCY = h * 0.28;

    final pathPaint = Paint()
      ..color = const Color(0xFFD4A96A).withAlpha(210)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Roads to each building
    pathPaint.strokeWidth = w * 0.038;

    // To wall (far left)
    _drawRoadSegment(canvas, pathPaint,
        start: Offset(castleCX, castleCY),
        ctrl: Offset(w * 0.18, h * 0.36),
        end: Offset(w * 0.08, h * 0.48));

    // To fireForge (left-center)
    _drawRoadSegment(canvas, pathPaint,
        start: Offset(castleCX, castleCY),
        ctrl: Offset(w * 0.30, h * 0.40),
        end: Offset(w * 0.23, h * 0.60));

    // To natureGrove (center-front)
    _drawRoadSegment(canvas, pathPaint,
        start: Offset(castleCX, castleCY),
        ctrl: Offset(w * 0.50, h * 0.46),
        end: Offset(w * 0.50, h * 0.64));

    // To waterWell (right-center)
    _drawRoadSegment(canvas, pathPaint,
        start: Offset(castleCX, castleCY),
        ctrl: Offset(w * 0.70, h * 0.40),
        end: Offset(w * 0.77, h * 0.60));

    // To mine (far right)
    _drawRoadSegment(canvas, pathPaint,
        start: Offset(castleCX, castleCY),
        ctrl: Offset(w * 0.82, h * 0.36),
        end: Offset(w * 0.87, h * 0.48));

    // Road highlight stripes
    final pathHighlight = Paint()
      ..color = const Color(0xFFEDD08A).withAlpha(120)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014;
    _drawRoadSegment(canvas, pathHighlight,
        start: Offset(castleCX, castleCY),
        ctrl: Offset(w * 0.50, h * 0.46),
        end: Offset(w * 0.50, h * 0.64));

    // ── Small pond (lower-right corner) ──────────────────────────────────────
    _drawPond(canvas, w * 0.88, h * 0.82, w * 0.07, h * 0.045);

    // ── Fence segments (lower edge) ───────────────────────────────────────────
    _drawFenceRow(canvas, w * 0.02, h * 0.88, w * 0.12, h);
    _drawFenceRow(canvas, w * 0.88, h * 0.88, w * 0.98, h);

    // ── Trees ─────────────────────────────────────────────────────────────────
    _drawTree(canvas, w * 0.04, h * 0.64, w * 0.06);
    _drawTree(canvas, w * 0.01, h * 0.56, w * 0.05);
    _drawTree(canvas, w * 0.96, h * 0.60, w * 0.06);
    _drawTree(canvas, w * 0.98, h * 0.70, w * 0.05);
    _drawTree(canvas, w * 0.10, h * 0.44, w * 0.038);
    _drawTree(canvas, w * 0.88, h * 0.46, w * 0.038);

    // ── Bushes ────────────────────────────────────────────────────────────────
    _drawBush(canvas, w * 0.22, h * 0.72, w * 0.045);
    _drawBush(canvas, w * 0.65, h * 0.74, w * 0.045);
    _drawBush(canvas, w * 0.13, h * 0.82, w * 0.035);
    _drawBush(canvas, w * 0.75, h * 0.84, w * 0.035);

    // ── Flowers (scattered dots) ──────────────────────────────────────────────
    const flowerPositions = [
      [0.06, 0.72],
      [0.16, 0.84],
      [0.27, 0.91],
      [0.36, 0.78],
      [0.45, 0.87],
      [0.55, 0.74],
      [0.67, 0.88],
      [0.78, 0.70],
      [0.86, 0.92],
      [0.92, 0.78],
    ];
    for (int i = 0; i < flowerPositions.length; i++) {
      final fx = w * flowerPositions[i][0];
      final fy = h * flowerPositions[i][1];
      final isYellow = i.isEven;
      _drawFlower(canvas, fx, fy, w * 0.011, isYellow);
    }
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()..color = Colors.white.withAlpha(210);
    canvas.drawCircle(Offset(cx, cy), r, paint);
    canvas.drawCircle(Offset(cx + r * 0.8, cy + r * 0.15), r * 0.75, paint);
    canvas.drawCircle(Offset(cx - r * 0.7, cy + r * 0.20), r * 0.65, paint);
    canvas.drawCircle(Offset(cx + r * 0.3, cy + r * 0.35), r * 0.70, paint);
  }

  void _drawRoadSegment(
    Canvas canvas,
    Paint paint, {
    required Offset start,
    required Offset ctrl,
    required Offset end,
  }) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  void _drawPond(Canvas canvas, double cx, double cy, double rx, double ry) {
    final pondRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
      ).createShader(pondRect);
    canvas.drawOval(pondRect, waterPaint);
    final shimmerPaint = Paint()
      ..color = Colors.white.withAlpha(80)
      ..strokeWidth = rx * 0.4
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - rx * 0.2, cy - ry * 0.2), width: rx * 0.9, height: ry * 0.5),
      -0.9, 1.2, false, shimmerPaint,
    );
    final rimPaint = Paint()
      ..color = const Color(0xFF4CAF50).withAlpha(180)
      ..strokeWidth = rx * 0.25
      ..style = PaintingStyle.stroke;
    canvas.drawOval(pondRect, rimPaint);
  }

  void _drawFenceRow(Canvas canvas, double x1, double y, double x2, double h) {
    final postPaint = Paint()..color = const Color(0xFF8D6E63);
    final railPaint = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const postW = 3.0;
    final postH = h * 0.07;
    final spacing = (x2 - x1) / 5;
    canvas.drawLine(Offset(x1, y + postH * 0.30), Offset(x2, y + postH * 0.30), railPaint);
    canvas.drawLine(Offset(x1, y + postH * 0.65), Offset(x2, y + postH * 0.65), railPaint);
    for (int i = 0; i <= 5; i++) {
      final px = x1 + i * spacing;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - postW / 2, y, postW, postH),
          const Radius.circular(1),
        ),
        postPaint,
      );
      final capPath = Path()
        ..moveTo(px - postW / 2, y)
        ..lineTo(px, y - postH * 0.18)
        ..lineTo(px + postW / 2, y)
        ..close();
      canvas.drawPath(capPath, postPaint);
    }
  }

  void _drawTree(Canvas canvas, double cx, double groundY, double r) {
    final trunkPaint = Paint()..color = const Color(0xFF6D4C41);
    final trunkW = r * 0.35;
    final trunkH = r * 0.70;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - trunkW / 2, groundY - trunkH, trunkW, trunkH),
        const Radius.circular(2),
      ),
      trunkPaint,
    );
    final shadowPaint = Paint()..color = const Color(0xFF4E342E).withAlpha(80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx, groundY - trunkH, trunkW * 0.4, trunkH),
        const Radius.circular(2),
      ),
      shadowPaint,
    );
    final darkLeaf = Paint()..color = const Color(0xFF388E3C);
    final midLeaf = Paint()..color = const Color(0xFF66BB6A);
    final lightLeaf = Paint()..color = const Color(0xFF81C784);
    canvas.drawCircle(Offset(cx, groundY - trunkH - r * 0.55), r, darkLeaf);
    canvas.drawCircle(Offset(cx - r * 0.4, groundY - trunkH - r * 0.35), r * 0.75, darkLeaf);
    canvas.drawCircle(Offset(cx + r * 0.4, groundY - trunkH - r * 0.35), r * 0.75, darkLeaf);
    canvas.drawCircle(Offset(cx, groundY - trunkH - r * 0.55), r * 0.80, midLeaf);
    canvas.drawCircle(Offset(cx - r * 0.15, groundY - trunkH - r * 0.75), r * 0.55, lightLeaf);
  }

  void _drawBush(Canvas canvas, double cx, double groundY, double r) {
    final darkPaint = Paint()..color = const Color(0xFF388E3C);
    final midPaint = Paint()..color = const Color(0xFF558B2F);
    canvas.drawCircle(Offset(cx, groundY), r, darkPaint);
    canvas.drawCircle(Offset(cx - r * 0.55, groundY + r * 0.15), r * 0.75, darkPaint);
    canvas.drawCircle(Offset(cx + r * 0.55, groundY + r * 0.15), r * 0.75, darkPaint);
    canvas.drawCircle(Offset(cx, groundY - r * 0.20), r * 0.70, midPaint);
  }

  void _drawFlower(Canvas canvas, double cx, double cy, double r, bool yellow) {
    final petalColor = yellow ? const Color(0xFFFFF176) : const Color(0xFFF48FB1);
    final centerColor = yellow ? const Color(0xFFFF8F00) : const Color(0xFFE91E63);
    final petalPaint = Paint()..color = petalColor.withAlpha(220);
    final centerPaint = Paint()..color = centerColor;
    for (int i = 0; i < 5; i++) {
      final petalCx = cx + r * 1.4 * _cos5(i);
      final petalCy = cy + r * 1.4 * _sin5(i);
      canvas.drawCircle(Offset(petalCx, petalCy), r, petalPaint);
    }
    canvas.drawCircle(Offset(cx, cy), r * 0.70, centerPaint);
  }

  double _cos5(int i) {
    const vals = [0.0, 0.309, -0.809, -0.809, 0.309];
    return vals[i % 5];
  }

  double _sin5(int i) {
    const vals = [-1.0, 0.951, 0.588, -0.588, -0.951];
    return vals[i % 5];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _PositionedBuilding
// ─────────────────────────────────────────────────────────────────────────────

class _PositionedBuilding extends StatelessWidget {
  final BuildingType type;
  final int level;
  final String title;
  final double size;
  final Offset offset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PositionedBuilding({
    required this.type,
    required this.level,
    required this.title,
    required this.size,
    required this.offset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colW = size + 8;

    Widget building = AnimatedScale(
      scale: isSelected ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF57C00).withAlpha(180),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: BuildingArt(type: type, level: level, size: size),
      ),
    );

    Widget column = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: colW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            building,
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF57C00)
                      : Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Text(
                  i < level ? '●' : '○',
                  style: TextStyle(
                    fontSize: 9,
                    color: i < level
                        ? const Color(0xFFF57C00)
                        : Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: column,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UpgradePanel — bottom info / action card
// ─────────────────────────────────────────────────────────────────────────────

class _UpgradePanel extends StatelessWidget {
  final BuildingType type;
  final String title;
  final String description;
  final int level;
  final String effect;
  final int crystals;
  final VoidCallback onUpgrade;

  const _UpgradePanel({
    required this.type,
    required this.title,
    required this.description,
    required this.level,
    required this.effect,
    required this.crystals,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final cost = KingdomEconomy.upgradeCost(type, level);
    final maxed = level >= 3;
    final canAfford = crystals >= cost;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            BuildingArt(type: type, level: level, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  _LevelPips(level: level),
                  const SizedBox(height: 4),
                  Text(
                    effect,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: level == 0 ? Colors.grey : const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            maxed
                ? const Chip(label: Text('МАКС'))
                : FilledButton(
                    onPressed: canAfford ? onUpgrade : null,
                    child: Text(
                      '${level == 0 ? 'Построить' : 'Улучшить'} ($cost💎)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LevelPips
// ─────────────────────────────────────────────────────────────────────────────

class _LevelPips extends StatelessWidget {
  final int level;

  const _LevelPips({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Text(
            i < level ? '●' : '○',
            style: TextStyle(
              fontSize: 14,
              color: i < level ? const Color(0xFFF57C00) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CraftSection
// ─────────────────────────────────────────────────────────────────────────────

class _CraftSection extends StatelessWidget {
  final SaveState save;
  final SaveController controller;

  const _CraftSection({required this.save, required this.controller});

  @override
  Widget build(BuildContext context) {
    const craftId = 'trump_lava_cat';
    final alreadyCrafted = save.ownedCardIds.contains(craftId);

    if (alreadyCrafted) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Козырь кузницы создан 🏆',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('🔮', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Особый козырь доступен в кузнице!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.tonal(
              onPressed: save.crystals >= 40
                  ? () {
                      controller.addCrystals(-40);
                      controller.grantCard(craftId);
                    }
                  : null,
              child: const Text(
                'Создать козырь (40💎)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
