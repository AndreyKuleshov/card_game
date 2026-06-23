# Task 9: Save State Model and Local Persistence - Report

## Summary
Successfully implemented SaveState model with JSON serialization and SaveStore persistence layer backed by shared_preferences, following TDD methodology.

## TDD Process

### Step 1-2: RED - Write failing test
Created `test/models/save_state_test.dart` with initial tests:
- `initial state has starter content`: expects SaveState.initial() to exist with crystals=0, unlockedNodeIndex=0, containing 'trump_starter_drake' and 13+ card IDs
- `json round-trip preserves all fields`: tests serialization/deserialization of SaveState with custom values

**Result: FAILED** - "No such file or directory: lib/models/save_state.dart"

```
test/models/save_state_test.dart:4:8: Error: Error when reading 'lib/models/save_state.dart': No such file or directory
```

### Step 3-4: GREEN - Implement SaveState
Created `lib/models/save_state.dart` with:
- Immutable `SaveState` class with fields: crystals (int), kingdom (Kingdom), ownedCardIds (Set<String>), unlockedNodeIndex (int)
- `const` constructor with required fields
- `static SaveState initial()`: returns SaveState with crystals=0, default Kingdom(), ownedCardIds containing 12 common IDs + 'trump_starter_drake', unlockedNodeIndex=0
- `copyWith()` method for immutable updates
- `toJson()`: serializes to Map<String, dynamic>, flattening Kingdom fields and converting ownedCardIds Set to List
- `factory SaveState.fromJson()`: deserializes from Map, reconstructing Kingdom and converting ownedCardIds back to Set

**Result: PASSED - 2 tests green**

```
00:00 +0: initial state has starter content
00:00 +1: json round-trip preserves all fields
00:00 +2: All tests passed!
```

### Step 5-6: Extend test for persistence
- Updated test file to import `SaveStore` and `SharedPreferences`
- Added `persistenceTests()` function with two tests:
  - `SaveStore returns initial when nothing stored`: verifies load() returns initial state when key absent
  - `SaveStore persists and reloads`: verifies save() and load() round-trip with mock SharedPreferences

Created `lib/models/save_store.dart` with:
- `SaveStore` class backed by SharedPreferences
- `static const _key = 'save_v1'` for storage key
- `Future<SaveState> load()`: retrieves JSON string from SharedPreferences, decodes, and deserializes; returns SaveState.initial() if key absent
- `Future<void> save(SaveState state)`: serializes SaveState to JSON and stores under 'save_v1' key

**Result: PASSED - 4 tests green**

```
00:00 +0: initial state has starter content
00:00 +1: json round-trip preserves all fields
00:00 +2: SaveStore returns initial when nothing stored
00:00 +3: SaveStore persists and reloads
00:00 +4: All tests passed!
```

### Step 7: Full test suite verification
Ran `flutter test` to ensure no regressions:

**Result: ALL 38 TESTS PASSED** (4 new + 34 existing)

```
00:00 +0-+4: test/models/save_state_test.dart (4 new tests)
00:00 +5: test/setup_smoke_test.dart
00:00 +6-+8: test/data/card_repository_test.dart
00:00 +9-+14: test/engine/element_test.dart
00:00 +15-+17: test/engine/deck_test.dart
00:00 +18-+28: test/engine/duel_engine_test.dart
00:00 +29-+32: test/engine/kingdom_test.dart
00:00 +33-+34: test/engine/ai_controller_test.dart
00:00 +35-+37: test/engine/game_card_test.dart
00:01 +38: All tests passed!
```

### Step 8: Commit
Successfully committed:
```
[feature/vertical-slice 28ebaee] feat: add save state model and shared_preferences persistence
 3 files changed, 139 insertions(+)
 create mode 100644 lib/models/save_state.dart
 create mode 100644 lib/models/save_store.dart
 create mode 100644 test/models/save_state_test.dart
```

## Files Created
1. `/Users/greenolls/cursor/card_game/lib/models/save_state.dart` (71 lines)
2. `/Users/greenolls/cursor/card_game/lib/models/save_store.dart` (18 lines)
3. `/Users/greenolls/cursor/card_game/test/models/save_state_test.dart` (47 lines)

## Implementation Details

### SaveState Model
- **Immutability**: All fields are final; copyWith() provides safe mutation pattern
- **Serialization**: Custom toJson/fromJson handle Kingdom nested object and Set<String> conversion
- **Initial state**: Contains 13 starter card IDs (12 common + 'trump_starter_drake') as specified
- **Default Kingdom**: Uses Kingdom() defaults (all levels 1, Element.fire barracks)

### SaveStore Persistence
- **Key**: 'save_v1' for future versioning support
- **Format**: jsonEncode(state.toJson()) stored as string
- **Load behavior**: Returns SaveState.initial() when key absent (no error thrown)
- **Async API**: load() and save() properly use await on SharedPreferences.getInstance()

## Test Coverage
All requirements from brief verified:
✓ SaveState.initial() has crystals=0, unlockedNodeIndex=0, contains starter cards
✓ JSON round-trip preserves all fields (crystals, kingdom properties, ownedCardIds, unlockedNodeIndex)
✓ SaveStore.load() returns initial when nothing stored
✓ SaveStore.save() and load() persist and restore state correctly

## No Concerns
- All tests pass (38/38)
- No regressions in existing test suite
- Code follows verbatim brief requirements
- TDD methodology followed: RED → GREEN → COMMIT
