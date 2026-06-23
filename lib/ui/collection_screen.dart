import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/ability.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets.dart';

/// Russian name for each trump ability.
String _abilityName(Ability ability) {
  switch (ability) {
    case Ability.elementalShift:
      return 'Стихийный сдвиг';
    case Ability.doubleStrike:
      return 'Двойной удар';
    case Ability.shield:
      return 'Щит';
  }
}

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);
    final save = ref.watch(saveStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Коллекция'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GameColors.backgroundStops,
          ),
        ),
        child: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Ошибка: $err')),
          data: (allCards) {
            final owned = allCards
                .where((c) => save.ownedCardIds.contains(c.id))
                .toList();
            final trumps =
                owned.where((c) => c.rarity == Rarity.trump).toList();
            final others =
                owned.where((c) => c.rarity != Rarity.trump).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Counter
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Козырей: ${trumps.length} · Всего карт: ${owned.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF795548),
                      ),
                    ),
                  ),

                  // ── Trumps section ───────────────────────────────────────
                  const Text(
                    '🏆 Козыри',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (trumps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Пока нет козырей — побеждай, крафти и бей боссов!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9E9E9E),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 16,
                        children: trumps.map((card) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GameCardView(
                                card: card,
                                width: 88,
                                highlighted: true,
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 92,
                                child: Text(
                                  card.ability != null
                                      ? _abilityName(card.ability!)
                                      : '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF57C00),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                  // ── Other cards section ──────────────────────────────────
                  const Text(
                    'Карты',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (others.isEmpty)
                    const Text(
                      'Нет обычных карт',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: others
                          .map((card) => GameCardView(card: card, width: 88))
                          .toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
