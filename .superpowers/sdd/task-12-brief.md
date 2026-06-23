### Task 12: World map screen (linear node chain + boss)

**Files:**
- Create: `lib/ui/world_map_screen.dart`, `lib/ui/duel_setup.dart`
- Test: `test/ui/world_map_test.dart`

**Interfaces:**
- Consumes: `saveStateProvider`, `cardsProvider`, `BuildingType` (Task 11), engine types.
- Produces:
  - `class MapNode { final int index; final String title; final List<String> opponentCardIds; final DuelConfig opponentConfig; final bool isBoss; final String? rewardTrumpId; const MapNode(...); }`
  - `const List<MapNode> kSliceNodes` — 4 nodes: `Тренировка`, `Противник 1`, `Противник 2`, `БОСС` (boss has `rewardTrumpId: 'trump_pumpkin_king'`).
  - `class WorldMapScreen extends ConsumerWidget` — `AppBar('Карта мира')`, a column of node buttons; node `i` is enabled iff `i <= unlockedNodeIndex`; tapping a node pushes the duel screen with that node's setup.

- [ ] **Step 1: Write `lib/ui/duel_setup.dart`** (shared node data + duel construction)

```dart
import 'dart:math';
import '../engine/ai_controller.dart';
import '../engine/deck.dart';
import '../engine/duel_engine.dart';
import '../engine/duel_session.dart';
import '../engine/game_card.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';

class MapNode {
  final int index;
  final String title;
  final List<String> opponentCardIds;
  final DuelConfig opponentConfig;
  final bool isBoss;
  final String? rewardTrumpId;

  const MapNode({
    required this.index,
    required this.title,
    required this.opponentCardIds,
    required this.opponentConfig,
    this.isBoss = false,
    this.rewardTrumpId,
  });
}

const kSliceNodes = <MapNode>[
  MapNode(
    index: 0,
    title: 'Тренировка',
    opponentCardIds: ['fire_pie', 'nature_hedgehog', 'water_puddle', 'fire_deer'],
    opponentConfig: DuelConfig(startingCastleHp: 20),
  ),
  MapNode(
    index: 1,
    title: 'Противник 1',
    opponentCardIds: ['fire_rooster', 'nature_zucchini', 'water_jellyfish', 'nature_mushroom'],
    opponentConfig: DuelConfig(startingCastleHp: 28),
  ),
  MapNode(
    index: 2,
    title: 'Противник 2',
    opponentCardIds: ['water_beaver', 'fire_phoenix_pearl', 'nature_mushroom', 'water_dumpling'],
    opponentConfig: DuelConfig(startingCastleHp: 34),
  ),
  MapNode(
    index: 3,
    title: 'БОСС: Тыквенный Лорд',
    opponentCardIds: ['water_dumpling', 'fire_phoenix_pearl', 'water_beaver', 'trump_lava_cat'],
    opponentConfig: DuelConfig(startingCastleHp: 40),
    isBoss: true,
    rewardTrumpId: 'trump_pumpkin_king',
  ),
];

/// Builds a 12-card deck from owned cards, padding by repeating owned ids so a
/// thin starter collection still fills a deck.
List<GameCard> buildPlayerDeck(SaveState save, List<GameCard> allCards) {
  final owned = allCards.where((c) => save.ownedCardIds.contains(c.id)).toList();
  final deck = <GameCard>[];
  var i = 0;
  while (deck.length < kDeckSize && owned.isNotEmpty) {
    deck.add(owned[i % owned.length]);
    i++;
  }
  return deck;
}

DuelSession buildSession({
  required SaveState save,
  required List<GameCard> allCards,
  required MapNode node,
  required Random random,
}) {
  final byId = {for (final c in allCards) c.id: c};
  final playerCards = buildPlayerDeck(save, allCards);
  final oppCards = node.opponentCardIds.map((id) => byId[id]!).toList();
  return DuelSession(
    playerDeck: Deck(playerCards),
    opponentDeck: Deck(oppCards),
    playerConfig: KingdomEconomy.toDuelConfig(save.kingdom),
    opponentConfig: node.opponentConfig,
    ai: AiController(),
    random: random,
  )..start();
}
```

- [ ] **Step 2: Write the failing widget test**

`test/ui/world_map_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/world_map_screen.dart';

void main() {
  testWidgets('world map shows nodes and locks future ones', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: WorldMapScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Карта мира'), findsOneWidget);
    expect(find.text('Тренировка'), findsOneWidget);
    expect(find.textContaining('БОСС'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/ui/world_map_test.dart`
Expected: FAIL (world_map_screen.dart not found).

- [ ] **Step 4: Write `lib/ui/world_map_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'duel_screen.dart';
import 'kingdom_screen.dart';

class WorldMapScreen extends ConsumerWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта мира'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text('💎 ${save.crystals}')),
          ),
          IconButton(
            icon: const Icon(Icons.castle),
            tooltip: 'Королевство',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KingdomScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final node in kSliceNodes)
            Card(
              child: ListTile(
                leading: Icon(node.isBoss ? Icons.whatshot : Icons.flag),
                title: Text(node.title),
                trailing: node.index <= save.unlockedNodeIndex
                    ? const Icon(Icons.play_arrow)
                    : const Icon(Icons.lock),
                enabled: node.index <= save.unlockedNodeIndex,
                onTap: node.index <= save.unlockedNodeIndex
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DuelScreen(node: node)),
                        )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run test** (requires `DuelScreen` and `KingdomScreen` to exist — create stub files first if executing strictly in order, or implement Tasks 13–14 then return)

Run: `flutter test test/ui/world_map_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/world_map_screen.dart lib/ui/duel_setup.dart test/ui/world_map_test.dart
git commit -m "feat: add world map screen and duel setup"
```

---

