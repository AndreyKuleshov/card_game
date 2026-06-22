import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';
import '../state/providers.dart';
import 'art.dart';
import 'theme.dart';
import 'widgets.dart';

class KingdomScreen extends ConsumerWidget {
  const KingdomScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CastlePainterView(size: 80),
              ),
            ),
            for (final type in BuildingType.values)
              _BuildingCard(
                type: type,
                title: _titles[type]!,
                level: k.levelOf(type),
                effect: _effect(type, k),
                crystals: save.crystals,
                onUpgrade: () => controller.tryUpgrade(type),
              ),
            if (k.barracksLevel >= 3)
              _CraftSection(save: save, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  final BuildingType type;
  final String title;
  final int level;
  final String effect;
  final int crystals;
  final VoidCallback onUpgrade;

  const _BuildingCard({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              BuildingArt(type: type, level: level, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        '${level == 0 ? 'Построить' : 'Улучшить'}\n($cost💎)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🔮', style: TextStyle(fontSize: 32)),
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
