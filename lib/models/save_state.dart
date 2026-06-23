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
        // Frontier starts at the first opponent (index 1); training (index 0)
        // is always available and does not move the frontier.
        unlockedNodeIndex: 1,
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
          'fireLevel': kingdom.fireLevel,
          'waterLevel': kingdom.waterLevel,
          'natureLevel': kingdom.natureLevel,
          'wallLevel': kingdom.wallLevel,
          'mineLevel': kingdom.mineLevel,
        },
        'ownedCardIds': ownedCardIds.toList(),
        'unlockedNodeIndex': unlockedNodeIndex,
      };

  factory SaveState.fromJson(Map<String, dynamic> json) {
    final k = json['kingdom'] as Map<String, dynamic>;
    return SaveState(
      crystals: json['crystals'] as int,
      kingdom: Kingdom(
        fireLevel: k['fireLevel'] as int,
        waterLevel: k['waterLevel'] as int,
        natureLevel: k['natureLevel'] as int,
        wallLevel: k['wallLevel'] as int,
        mineLevel: k['mineLevel'] as int,
      ),
      ownedCardIds: (json['ownedCardIds'] as List<dynamic>).cast<String>().toSet(),
      // Migrate old saves where the frontier started at 0 (training).
      unlockedNodeIndex: (json['unlockedNodeIndex'] as int) < 1
          ? 1
          : json['unlockedNodeIndex'] as int,
    );
  }
}
