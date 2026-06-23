### Task 9: Save state model and local persistence

**Files:**
- Create: `lib/models/save_state.dart`, `lib/models/save_store.dart`
- Test: `test/models/save_state_test.dart`

**Interfaces:**
- Consumes: `Kingdom`, `Element`, `BuildingType` (Task 7).
- Produces:
  - `class SaveState { final int crystals; final Kingdom kingdom; final Set<String> ownedCardIds; final int unlockedNodeIndex; const SaveState({...}); SaveState copyWith({...}); Map<String,dynamic> toJson(); factory SaveState.fromJson(Map<String,dynamic>); static SaveState initial(); }`
  - `initial()`: crystals 0, default `Kingdom`, owns the 12 common card ids + `trump_starter_drake`, `unlockedNodeIndex = 0`.
  - `class SaveStore { Future<SaveState> load(); Future<void> save(SaveState state); }` backed by `shared_preferences` under key `save_v1` (stores `jsonEncode(state.toJson())`); `load()` returns `SaveState.initial()` when absent.

- [ ] **Step 1: Write the failing test**

`test/models/save_state_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/kingdom.dart';
import 'package:card_game/models/save_state.dart';

void main() {
  test('initial state has starter content', () {
    final s = SaveState.initial();
    expect(s.crystals, 0);
    expect(s.unlockedNodeIndex, 0);
    expect(s.ownedCardIds, contains('trump_starter_drake'));
    expect(s.ownedCardIds.length, greaterThanOrEqualTo(13));
  });

  test('json round-trip preserves all fields', () {
    final s = SaveState(
      crystals: 42,
      kingdom: const Kingdom(barracksLevel: 2, wallLevel: 3, mineLevel: 1, barracksElement: Element.water),
      ownedCardIds: {'a', 'b'},
      unlockedNodeIndex: 2,
    );
    final restored = SaveState.fromJson(s.toJson());
    expect(restored.crystals, 42);
    expect(restored.kingdom.wallLevel, 3);
    expect(restored.kingdom.barracksElement, Element.water);
    expect(restored.ownedCardIds, {'a', 'b'});
    expect(restored.unlockedNodeIndex, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/save_state_test.dart`
Expected: FAIL (save_state.dart not found).

- [ ] **Step 3: Write `lib/models/save_state.dart`**

```dart
import '../engine/element.dart';
import '../engine/kingdom.dart';

const _starterCommonIds = [
  'fire_deer', 'fire_rooster', 'fire_pie', 'fire_phoenix_pearl',
  'nature_zucchini', 'nature_forester', 'nature_mushroom', 'nature_hedgehog',
  'water_jellyfish', 'water_puddle', 'water_beaver', 'water_dumpling',
];

class SaveState {
  final int crystals;
  final Kingdom kingdom;
  final Set<String> ownedCardIds;
  final int unlockedNodeIndex;

  const SaveState({
    required this.crystals,
    required this.kingdom,
    required this.ownedCardIds,
    required this.unlockedNodeIndex,
  });

  static SaveState initial() => SaveState(
        crystals: 0,
        kingdom: const Kingdom(),
        ownedCardIds: {..._starterCommonIds, 'trump_starter_drake'},
        unlockedNodeIndex: 0,
      );

  SaveState copyWith({
    int? crystals,
    Kingdom? kingdom,
    Set<String>? ownedCardIds,
    int? unlockedNodeIndex,
  }) {
    return SaveState(
      crystals: crystals ?? this.crystals,
      kingdom: kingdom ?? this.kingdom,
      ownedCardIds: ownedCardIds ?? this.ownedCardIds,
      unlockedNodeIndex: unlockedNodeIndex ?? this.unlockedNodeIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'crystals': crystals,
        'kingdom': {
          'barracksLevel': kingdom.barracksLevel,
          'wallLevel': kingdom.wallLevel,
          'mineLevel': kingdom.mineLevel,
          'barracksElement': kingdom.barracksElement.name,
        },
        'ownedCardIds': ownedCardIds.toList(),
        'unlockedNodeIndex': unlockedNodeIndex,
      };

  factory SaveState.fromJson(Map<String, dynamic> json) {
    final k = json['kingdom'] as Map<String, dynamic>;
    return SaveState(
      crystals: json['crystals'] as int,
      kingdom: Kingdom(
        barracksLevel: k['barracksLevel'] as int,
        wallLevel: k['wallLevel'] as int,
        mineLevel: k['mineLevel'] as int,
        barracksElement:
            Element.values.firstWhere((e) => e.name == k['barracksElement']),
      ),
      ownedCardIds: (json['ownedCardIds'] as List<dynamic>).cast<String>().toSet(),
      unlockedNodeIndex: json['unlockedNodeIndex'] as int,
    );
  }
}
```

- [ ] **Step 4: Run the round-trip test (no persistence yet)**

Run: `flutter test test/models/save_state_test.dart`
Expected: PASS.

- [ ] **Step 5: Write `lib/models/save_store.dart`**

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'save_state.dart';

class SaveStore {
  static const _key = 'save_v1';

  Future<SaveState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return SaveState.initial();
    return SaveState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(SaveState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
```

- [ ] **Step 6: Add a persistence test using the in-memory prefs backend**

Append to `test/models/save_state_test.dart`:
```dart
// Add these imports at the top of the file:
// import 'package:card_game/models/save_store.dart';
// import 'package:shared_preferences/shared_preferences.dart';

void persistenceTests() {
  test('SaveStore returns initial when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await SaveStore().load();
    expect(state.crystals, 0);
  });

  test('SaveStore persists and reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SaveStore();
    await store.save(SaveState.initial().copyWith(crystals: 99));
    final reloaded = await store.load();
    expect(reloaded.crystals, 99);
  });
}
```
Then call `persistenceTests();` at the end of `main()` in that file (and add the two imports shown).

- [ ] **Step 7: Run all model tests**

Run: `flutter test test/models/save_state_test.dart`
Expected: PASS (round-trip + 2 persistence tests).

- [ ] **Step 8: Commit**

```bash
git add lib/models/save_state.dart lib/models/save_store.dart test/models/save_state_test.dart
git commit -m "feat: add save state model and shared_preferences persistence"
```

---

