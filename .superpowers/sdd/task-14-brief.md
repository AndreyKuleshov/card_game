### Task 14: Duel screen and reward flow

**Files:**
- Create: `lib/ui/duel_screen.dart`, `lib/ui/reward_screen.dart`
- Test: `test/ui/duel_screen_test.dart`

**Interfaces:**
- Consumes: `DuelSession`, `MapNode`, `buildSession`, `saveStateProvider`, `SaveController` (Tasks 10–12), `RoundResult`.
- Produces:
  - `class DuelScreen extends ConsumerStatefulWidget { final MapNode node; }` — builds a `DuelSession` in `initState` (seeded `Random` from `node.index` for determinism in tests), shows both castle HP bars, the player hand as tappable cards, the last round result; on `DuelOutcome` resolved, navigates to `RewardScreen`.
  - On player win: grant crystals (`5 + kingdom.mineCrystalsPerWin`), if node not yet cleared `unlockNextNode()`, on boss grant `rewardTrumpId`, ~30% chest roll (seeded) grants `trump_frost_granny`.
  - `class RewardScreen extends StatelessWidget { final bool won; final int crystalsEarned; final String? trumpGranted; }` — summary + «В королевство» button popping to the map.

- [ ] **Step 1: Write the failing widget test**

`test/ui/duel_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/duel_screen.dart';
import 'package:card_game/ui/duel_setup.dart';

void main() {
  testWidgets('duel screen renders castle hp and a playable hand', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: DuelScreen(node: kSliceNodes.first)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Замок'), findsWidgets);
    // Hand cards are rendered as InkWell-wrapped tiles; at least one exists.
    expect(find.byType(Card), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/duel_screen_test.dart`
Expected: FAIL (duel_screen.dart not found).

- [ ] **Step 3: Write `lib/ui/reward_screen.dart`**

```dart
import 'package:flutter/material.dart';

class RewardScreen extends StatelessWidget {
  final bool won;
  final int crystalsEarned;
  final String? trumpGranted;

  const RewardScreen({
    super.key,
    required this.won,
    required this.crystalsEarned,
    this.trumpGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(won ? 'Победа!' : 'Поражение')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(won ? '🎉 Замок врага пал!' : '💥 Твой замок разрушен',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (won) Text('Получено: 💎 $crystalsEarned'),
            if (trumpGranted != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('🏆 Новый козырь: $trumpGranted'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
              child: const Text('В королевство'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write `lib/ui/duel_screen.dart`**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/duel_session.dart';
import '../engine/game_card.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'reward_screen.dart';

class DuelScreen extends ConsumerStatefulWidget {
  final MapNode node;
  const DuelScreen({super.key, required this.node});

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  DuelSession? _session;
  String _log = 'Выбери карту';
  bool _resolved = false;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsProvider);
    final save = ref.watch(saveStateProvider);

    return cardsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Ошибка: $e'))),
      data: (allCards) {
        final session = _session ??= buildSession(
          save: save,
          allCards: allCards,
          node: widget.node,
          random: Random(widget.node.index + 1),
        );
        return Scaffold(
          appBar: AppBar(title: Text(widget.node.title)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Замок врага: ${session.opponentCastleHp}'),
                Text('Твой Замок: ${session.playerCastleHp}'),
                const SizedBox(height: 12),
                Text(_log),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final card in session.playerHand)
                      Card(
                        child: InkWell(
                          onTap: _resolved ? null : () => _play(card, session),
                          child: SizedBox(
                            width: 80,
                            height: 110,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_elementEmoji(card),
                                      style: const TextStyle(fontSize: 22)),
                                  Text(card.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10)),
                                  Text('${card.power}',
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _elementEmoji(GameCard c) =>
      {'fire': '🔥', 'nature': '🌿', 'water': '💧'}[c.element.name]!;

  void _play(GameCard card, DuelSession session) {
    final result = session.playPlayerCard(card);
    setState(() {
      _log = 'Раунд: ${result.playerEffectivePower} против '
          '${result.opponentEffectivePower}, урон ${result.damage}';
    });
    final outcome = session.outcome;
    if (outcome != DuelOutcome.ongoing && !_resolved) {
      _resolved = true;
      _finish(outcome == DuelOutcome.playerWon);
    } else {
      setState(() {}); // refresh hand
    }
  }

  void _finish(bool won) {
    final controller = ref.read(saveStateProvider.notifier);
    final save = ref.read(saveStateProvider);
    var earned = 0;
    String? trump;
    if (won) {
      earned = 5 + save.kingdom.mineCrystalsPerWin;
      controller.addCrystals(earned);
      if (widget.node.index >= save.unlockedNodeIndex &&
          widget.node.index < kSliceNodes.length - 1) {
        controller.unlockNextNode();
      }
      if (widget.node.rewardTrumpId != null) {
        trump = widget.node.rewardTrumpId;
        controller.grantCard(trump!);
      } else if (Random(widget.node.index + 7).nextDouble() < 0.30) {
        trump = 'trump_frost_granny';
        controller.grantCard(trump);
      }
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) =>
          RewardScreen(won: won, crystalsEarned: earned, trumpGranted: trump),
    ));
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/ui/duel_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/duel_screen.dart lib/ui/reward_screen.dart test/ui/duel_screen_test.dart
git commit -m "feat: add duel screen and post-duel reward flow"
```

---

