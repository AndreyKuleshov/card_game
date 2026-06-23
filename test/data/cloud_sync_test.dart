import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/data/cloud_sync.dart';
import 'package:card_game/engine/kingdom.dart';
import 'package:card_game/models/save_state.dart';

void main() {
  group('mergeProgress', () {
    SaveState makeState({
      Set<String> cards = const {},
      int nodeIndex = 0,
      int fireLevel = 0,
      int waterLevel = 0,
      int natureLevel = 0,
      int wallLevel = 0,
      int mineLevel = 0,
      int crystals = 0,
    }) {
      return SaveState(
        crystals: crystals,
        kingdom: Kingdom(
          fireLevel: fireLevel,
          waterLevel: waterLevel,
          natureLevel: natureLevel,
          wallLevel: wallLevel,
          mineLevel: mineLevel,
        ),
        ownedCardIds: cards,
        unlockedNodeIndex: nodeIndex,
      );
    }

    test('ownedCardIds is UNION of local and cloud', () {
      final local = makeState(cards: {'card_a', 'card_b'});
      final cloud = makeState(cards: {'card_b', 'card_c'});

      final result = mergeProgress(local: local, cloud: cloud, cloudIsNewer: false);

      expect(result.ownedCardIds, containsAll(['card_a', 'card_b', 'card_c']));
      expect(result.ownedCardIds.length, 3);
    });

    test('unlockedNodeIndex is MAX of local and cloud', () {
      final local = makeState(nodeIndex: 5);
      final cloud = makeState(nodeIndex: 3);

      final result = mergeProgress(local: local, cloud: cloud, cloudIsNewer: true);

      expect(result.unlockedNodeIndex, 5);
    });

    test('unlockedNodeIndex picks cloud when cloud is larger', () {
      final local = makeState(nodeIndex: 2);
      final cloud = makeState(nodeIndex: 7);

      final result = mergeProgress(local: local, cloud: cloud, cloudIsNewer: false);

      expect(result.unlockedNodeIndex, 7);
    });

    test('kingdom levels are MAX of each building', () {
      final local = makeState(fireLevel: 3, waterLevel: 1, natureLevel: 2, wallLevel: 0, mineLevel: 2);
      final cloud = makeState(fireLevel: 1, waterLevel: 2, natureLevel: 2, wallLevel: 3, mineLevel: 1);

      final result = mergeProgress(local: local, cloud: cloud, cloudIsNewer: false);

      expect(result.kingdom.fireLevel, 3);
      expect(result.kingdom.waterLevel, 2);
      expect(result.kingdom.natureLevel, 2);
      expect(result.kingdom.wallLevel, 3);
      expect(result.kingdom.mineLevel, 2);
    });

    test('crystals come from cloud when cloudIsNewer is true', () {
      final local = makeState(crystals: 100);
      final cloud = makeState(crystals: 50);

      final result = mergeProgress(local: local, cloud: cloud, cloudIsNewer: true);

      expect(result.crystals, 50);
    });

    test('crystals come from local when cloudIsNewer is false', () {
      final local = makeState(crystals: 100);
      final cloud = makeState(crystals: 50);

      final result = mergeProgress(local: local, cloud: cloud, cloudIsNewer: false);

      expect(result.crystals, 100);
    });
  });
}
