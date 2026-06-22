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
  BuildingType _selected = BuildingType.barracks;

  static const _titles = {
    BuildingType.barracks: 'Казарма',
    BuildingType.wall: 'Стена',
    BuildingType.mine: 'Шахта',
  };

  String _effect(BuildingType type, Kingdom k) {
    if (k.levelOf(type) == 0) return 'Не построено';
    switch (type) {
      case BuildingType.barracks:
        return '+${k.barracksBonus} к силе карт стихии';
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

              // Scene: constrained to max 520 wide; height ~ 58% of available.
              final sceneW = availW.clamp(0.0, 520.0);
              final sceneH = (availH * 0.58).clamp(180.0, 320.0);

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
                            level: k.levelOf(_selected),
                            effect: _effect(_selected, k),
                            crystals: save.crystals,
                            onUpgrade: () => controller.tryUpgrade(_selected),
                          ),
                          if (k.barracksLevel >= 3) ...[
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

            // Castle centred slightly above middle.
            final castleSize = (w * 0.28).clamp(64.0, 110.0);

            // Building widget size — scales with scene width.
            final bldSize = (w * 0.18).clamp(48.0, 72.0);

            // Positions (fraction of scene size).
            // barracks: upper-left, mine: upper-right, wall: front-centre.
            final positions = {
              BuildingType.barracks: Offset(w * 0.13, h * 0.28),
              BuildingType.mine: Offset(w * 0.69, h * 0.28),
              BuildingType.wall: Offset(w * 0.38, h * 0.55),
            };

            return Stack(
              children: [
                // Castle at centre/back.
                Positioned(
                  left: w / 2 - castleSize / 2,
                  top: h * 0.08,
                  child: CastlePainterView(size: castleSize),
                ),

                // Buildings.
                for (final type in BuildingType.values)
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
// _MeadowPainter — the "plot of land" background
// ─────────────────────────────────────────────────────────────────────────────

class _MeadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient (top portion).
    final skyRect = Rect.fromLTWH(0, 0, w, h * 0.50);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF90CAF9), Color(0xFFB3E5FC)],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Meadow (rounded rect in lower portion).
    final meadowRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, h * 0.35, w, h * 0.65),
      topLeft: const Radius.circular(32),
      topRight: const Radius.circular(32),
    );
    final meadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8BC34A), Color(0xFF558B2F)],
      ).createShader(Rect.fromLTWH(0, h * 0.35, w, h * 0.65));
    canvas.drawRRect(meadowRect, meadowPaint);

    // Dirt path from castle to bottom (subtle).
    final pathPaint = Paint()..color = const Color(0xFFD7CCC8).withAlpha(120);
    final dirtPath = Path()
      ..moveTo(w * 0.43, h * 0.45)
      ..quadraticBezierTo(w * 0.50, h * 0.70, w * 0.50, h)
      ..quadraticBezierTo(w * 0.57, h * 0.70, w * 0.57, h * 0.45)
      ..close();
    canvas.drawPath(dirtPath, pathPaint);

    // Decorative small flowers (dots).
    final flowerPaint = Paint()..color = const Color(0xFFFFF176).withAlpha(180);
    for (final pos in [
      Offset(w * 0.08, h * 0.62),
      Offset(w * 0.18, h * 0.78),
      Offset(w * 0.82, h * 0.58),
      Offset(w * 0.90, h * 0.75),
      Offset(w * 0.30, h * 0.88),
      Offset(w * 0.70, h * 0.85),
    ]) {
      canvas.drawCircle(pos, 4, flowerPaint);
    }
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
    // Column width = size + padding for label.
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
            // Title label — FittedBox avoids overflow.
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Level pips.
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
  final int level;
  final String effect;
  final int crystals;
  final VoidCallback onUpgrade;

  const _UpgradePanel({
    required this.type,
    required this.title,
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
                  _LevelPips(level: level),
                  const SizedBox(height: 4),
                  Text(
                    effect,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
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
