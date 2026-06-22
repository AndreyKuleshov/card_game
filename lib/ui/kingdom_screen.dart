import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/kingdom.dart';
import '../state/providers.dart';

class KingdomScreen extends ConsumerWidget {
  const KingdomScreen({super.key});

  static const _titles = {
    BuildingType.barracks: 'Казарма',
    BuildingType.wall: 'Стена',
    BuildingType.mine: 'Шахта',
  };

  String _effect(BuildingType type, Kingdom k) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text('💎 ${save.crystals}')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final type in BuildingType.values)
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(_titles[type]!),
                    subtitle: Text('Ур. ${k.levelOf(type)} — ${_effect(type, k)}'),
                    trailing: k.levelOf(type) >= 3
                        ? const Text('МАКС')
                        : FilledButton(
                            onPressed: save.crystals >=
                                    KingdomEconomy.upgradeCost(type, k.levelOf(type))
                                ? () => controller.tryUpgrade(type)
                                : null,
                            child: Text(
                                'Улучшить (${KingdomEconomy.upgradeCost(type, k.levelOf(type))}💎)'),
                          ),
                  ),
                  if (type == BuildingType.barracks && k.barracksLevel >= 3)
                    Builder(builder: (context) {
                      const craftId = 'trump_lava_cat';
                      final alreadyCrafted = save.ownedCardIds.contains(craftId);
                      if (alreadyCrafted) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Козырь кузницы создан'),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: FilledButton.tonal(
                          onPressed: save.crystals >= 40
                              ? () {
                                  controller.addCrystals(-40);
                                  controller.grantCard(craftId);
                                }
                              : null,
                          child: const Text('Создать козырь (40💎)'),
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
