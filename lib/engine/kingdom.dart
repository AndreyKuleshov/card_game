import 'duel_engine.dart';
import 'element.dart';

enum BuildingType { barracks, wall, mine }

class Kingdom {
  final int barracksLevel;
  final int wallLevel;
  final int mineLevel;
  final Element barracksElement;

  const Kingdom({
    this.barracksLevel = 0,
    this.wallLevel = 0,
    this.mineLevel = 0,
    this.barracksElement = Element.fire,
  });

  int get barracksBonus => barracksLevel; // 0/1/2/3 (level 0 = not built)
  int get wallHpBonus => wallLevel * 5; // 0/5/10/15
  int get mineCrystalsPerWin => mineLevel * 2; // 0/2/4/6

  int levelOf(BuildingType type) {
    switch (type) {
      case BuildingType.barracks:
        return barracksLevel;
      case BuildingType.wall:
        return wallLevel;
      case BuildingType.mine:
        return mineLevel;
    }
  }

  Kingdom upgraded(BuildingType type) {
    int cap(int level) => level >= 3 ? 3 : level + 1;
    switch (type) {
      case BuildingType.barracks:
        return copyWith(barracksLevel: cap(barracksLevel));
      case BuildingType.wall:
        return copyWith(wallLevel: cap(wallLevel));
      case BuildingType.mine:
        return copyWith(mineLevel: cap(mineLevel));
    }
  }

  Kingdom copyWith({
    int? barracksLevel,
    int? wallLevel,
    int? mineLevel,
    Element? barracksElement,
  }) {
    return Kingdom(
      barracksLevel: barracksLevel ?? this.barracksLevel,
      wallLevel: wallLevel ?? this.wallLevel,
      mineLevel: mineLevel ?? this.mineLevel,
      barracksElement: barracksElement ?? this.barracksElement,
    );
  }
}

class KingdomEconomy {
  const KingdomEconomy._();

  /// Crystal cost to build/upgrade *from* [currentLevel]. Level 0 = not built
  /// yet (build cost); level 3 is the cap (cost 0).
  static int upgradeCost(BuildingType type, int currentLevel) {
    switch (currentLevel) {
      case 0:
        return 5;
      case 1:
        return 10;
      case 2:
        return 25;
      default:
        return 0; // already max
    }
  }

  static DuelConfig toDuelConfig(Kingdom k) {
    return DuelConfig(
      startingCastleHp: 30 + k.wallHpBonus,
      barracksElement: k.barracksElement,
      barracksBonus: k.barracksBonus,
    );
  }
}
