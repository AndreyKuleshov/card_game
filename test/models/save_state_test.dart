import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/kingdom.dart';
import 'package:card_game/models/save_state.dart';
import 'package:card_game/models/save_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  persistenceTests();
}

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
