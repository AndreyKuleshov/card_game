import 'duel_engine.dart';
import 'element.dart';

enum BuildingType { barracks, wall, mine }

class Kingdom {
  final int barracksLevel;
  final int wallLevel;
  final int mineLevel;
  final Element barracksElement;

  const Kingdom({
    this.barracksLevel = 1,
    this.wallLevel = 1,
    this.mineLevel = 1,
    this.barracksElement = Element.fire,
  });

  int get barracksBonus => barracksLevel; // 1/2/3
  int get wallHpBonus => wallLevel * 5; // 5/10/15
  int get mineCrystalsPerWin => mineLevel * 2; // 2/4/6

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

  /// Crystal cost to upgrade *from* [currentLevel]. Level 3 is the cap.
  static int upgradeCost(BuildingType type, int currentLevel) {
    switch (currentLevel) {
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
