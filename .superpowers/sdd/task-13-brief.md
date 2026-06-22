### Task 13: Kingdom screen (buildings + upgrades)

**Files:**
- Create: `lib/ui/kingdom_screen.dart`
- Test: `test/ui/kingdom_screen_test.dart`

**Interfaces:**
- Consumes: `saveStateProvider`, `SaveController.tryUpgrade`, `BuildingType`, `KingdomEconomy` (Tasks 7, 11).
- Produces: `class KingdomScreen extends ConsumerWidget` — lists the three buildings with level, effect text, cost, and an «Улучшить» button calling `tryUpgrade`; disabled at level 3 or when crystals are insufficient.

- [ ] **Step 1: Write the failing widget test**

`test/ui/kingdom_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/kingdom_screen.dart';

void main() {
  testWidgets('kingdom screen lists three buildings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: KingdomScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Казарма'), findsOneWidget);
    expect(find.text('Стена'), findsOneWidget);
    expect(find.text('Шахта'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/kingdom_screen_test.dart`
Expected: FAIL (kingdom_screen.dart not found).

- [ ] **Step 3: Write `lib/ui/kingdom_screen.dart`**

```dart
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
              child: ListTile(
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
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/kingdom_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/kingdom_screen.dart test/ui/kingdom_screen_test.dart
git commit -m "feat: add kingdom screen with building upgrades"
```

---

### Task 13b: Craft a trump at Barracks level 3

**Files:**
- Modify: `lib/ui/kingdom_screen.dart`
- Test: `test/ui/kingdom_screen_test.dart` (extend)

**Interfaces:**
- Consumes: `saveStateProvider`, `SaveController.tryUpgrade`/`addCrystals`/`grantCard`, `Kingdom.barracksLevel`.
- Produces: a «Создать козырь (40💎)» button in the Barracks card, visible only when `barracksLevel == 3` and the craft trump (`trump_pumpkin_king` if not owned, else `trump_frost_granny`) is not yet owned; on tap, if `crystals >= 40`, deduct 40 and `grantCard`.

- [ ] **Step 1: Extend the kingdom test**

Append to `test/ui/kingdom_screen_test.dart`:
```dart
// add at top: import 'package:card_game/state/providers.dart';
// add at top: import 'package:card_game/engine/kingdom.dart';

testWidgets('craft button appears only at barracks level 3', (tester) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  // Force barracks to level 3 with plenty of crystals.
  final ctrl = container.read(saveStateProvider.notifier);
  ctrl.addCrystals(100);
  ctrl.tryUpgrade(BuildingType.barracks); // 1->2
  ctrl.tryUpgrade(BuildingType.barracks); // 2->3
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: KingdomScreen()),
  ));
  await tester.pumpAndSettle();
  expect(find.textContaining('Создать козырь'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/kingdom_screen_test.dart`
Expected: FAIL (no craft button).

- [ ] **Step 3: Add the craft UI to the Barracks card in `kingdom_screen.dart`**

Inside the `ListTile` for buildings, after the upgrade button logic, add a craft row under the Barracks tile. Replace the `Card(...)` body in the `for` loop with a column that appends the craft button when applicable:
```dart
// Replace the `child: ListTile(...)` of the Card with:
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
        const craftId = 'trump_pumpkin_king';
        const altId = 'trump_frost_granny';
        final target = save.ownedCardIds.contains(craftId) ? altId : craftId;
        if (save.ownedCardIds.contains(target)) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Все козыри кузницы созданы'),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.tonal(
            onPressed: save.crystals >= 40
                ? () {
                    controller.addCrystals(-40);
                    controller.grantCard(target);
                  }
                : null,
            child: const Text('Создать козырь (40💎)'),
          ),
        );
      }),
  ],
),
```
Note: `addCrystals(-40)` reuses the existing mutator; it already persists. Ensure `SaveController.addCrystals` accepts negative values (it does — plain addition).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/kingdom_screen_test.dart`
Expected: PASS (both kingdom tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/kingdom_screen.dart test/ui/kingdom_screen_test.dart
git commit -m "feat: add trump crafting at barracks level 3"
```

---

## Done criteria

- `flutter analyze` clean, `flutter test` green.
- A player can: clear the training node, earn crystals, upgrade all three buildings, craft a trump at Barracks lv.3, win a chest-drop trump, and beat the boss to claim «Король-Тыква».
- All three trump-acquisition paths (boss, craft, chest) are reachable in one playthrough.
