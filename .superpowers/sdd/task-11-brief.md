### Task 11: Riverpod providers and app shell

**Files:**
- Create: `lib/state/providers.dart`, `lib/ui/app.dart`, `lib/main.dart` (replace generated)
- Test: `test/ui/app_smoke_test.dart`

**Interfaces:**
- Consumes: `SaveState`, `SaveStore`, `CardRepository`, `GameCard` (Tasks 8–9).
- Produces:
  - `final saveStoreProvider = Provider<SaveStore>(...)`
  - `final cardsProvider = FutureProvider<List<GameCard>>(...)` (loads asset)
  - `final saveStateProvider = StateNotifierProvider<SaveController, SaveState>(...)`
  - `class SaveController extends StateNotifier<SaveState> { SaveController(this._store, SaveState initial); Future<void> hydrate(); void addCrystals(int n); bool tryUpgrade(BuildingType type); void grantCard(String id); void unlockNextNode(); }` — every mutator persists via `_store.save(state)`.
  - `class CardGameApp extends StatelessWidget` (the `MaterialApp` root, `home: WorldMapScreen`).

- [ ] **Step 1: Write `lib/state/providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/card_repository.dart';
import '../engine/game_card.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';
import '../models/save_store.dart';

final saveStoreProvider = Provider<SaveStore>((ref) => SaveStore());

final cardsProvider = FutureProvider<List<GameCard>>((ref) async {
  return CardRepository.loadFromAsset();
});

final saveStateProvider =
    StateNotifierProvider<SaveController, SaveState>((ref) {
  return SaveController(ref.read(saveStoreProvider), SaveState.initial());
});

class SaveController extends StateNotifier<SaveState> {
  final SaveStore _store;
  SaveController(this._store, SaveState initial) : super(initial);

  Future<void> hydrate() async {
    state = await _store.load();
  }

  void _commit(SaveState next) {
    state = next;
    _store.save(next);
  }

  void addCrystals(int n) => _commit(state.copyWith(crystals: state.crystals + n));

  bool tryUpgrade(BuildingType type) {
    final level = state.kingdom.levelOf(type);
    if (level >= 3) return false;
    final cost = KingdomEconomy.upgradeCost(type, level);
    if (state.crystals < cost) return false;
    _commit(state.copyWith(
      crystals: state.crystals - cost,
      kingdom: state.kingdom.upgraded(type),
    ));
    return true;
  }

  void grantCard(String id) {
    if (state.ownedCardIds.contains(id)) return;
    _commit(state.copyWith(ownedCardIds: {...state.ownedCardIds, id}));
  }

  void unlockNextNode() =>
      _commit(state.copyWith(unlockedNodeIndex: state.unlockedNodeIndex + 1));
}
```

- [ ] **Step 2: Write `lib/ui/app.dart`** (imports `WorldMapScreen` from Task 12 — create that file before running)

```dart
import 'package:flutter/material.dart';
import 'world_map_screen.dart';

class CardGameApp extends StatelessWidget {
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Карточное Королевство',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const WorldMapScreen(),
    );
  }
}
```

- [ ] **Step 3: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/providers.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(saveStateProvider.notifier).hydrate();
  runApp(UncontrolledProviderScope(container: container, child: const CardGameApp()));
}
```

- [ ] **Step 4: Write a smoke test** (after Task 12's screen exists)

`test/ui/app_smoke_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/app.dart';

void main() {
  testWidgets('app boots to the world map', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: CardGameApp()));
    await tester.pumpAndSettle();
    expect(find.text('Карта мира'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run the smoke test** (after Task 12)

Run: `flutter test test/ui/app_smoke_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/state/providers.dart lib/ui/app.dart lib/main.dart test/ui/app_smoke_test.dart
git commit -m "feat: add riverpod providers and app shell"
```

> Note: Steps 4–5 depend on `WorldMapScreen` (Task 12). If executing strictly in order, write Task 12's screen first, then run these. Commit this task after Task 12 compiles.

---

