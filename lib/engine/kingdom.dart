import 'duel_engine.dart';
import 'element.dart';

/// Kingdom buildings. Three elemental forges grant per-element power bonuses;
/// the wall adds castle HP and the mine produces crystals.
enum BuildingType {
  fireForge, // 🔥 Зажигалка → бонус огню
  waterWell, // 💧 Полторашка → бонус воде
  natureGrove, // 🌿 Травка → бонус природе
  wall, // 🧱 Стена → +ХП замка
  mine, // ⛏️ Шахта → +кристаллы
}

/// The element a forge boosts, or null for non-forge buildings.
Element? forgeElement(BuildingType type) {
  switch (type) {
    case BuildingType.fireForge:
      return Element.fire;
    case BuildingType.waterWell:
      return Element.water;
    case BuildingType.natureGrove:
      return Element.nature;
    case BuildingType.wall:
    case BuildingType.mine:
      return null;
  }
}

class Kingdom {
  final int fireLevel;
  final int waterLevel;
  final int natureLevel;
  final int wallLevel;
  final int mineLevel;

  const Kingdom({
    this.fireLevel = 0,
    this.waterLevel = 0,
    this.natureLevel = 0,
    this.wallLevel = 0,
    this.mineLevel = 0,
  });

  /// Power bonus a card of [element] gets from its matching forge (0/1/2/3).
  int elementBonus(Element element) {
    switch (element) {
      case Element.fire:
        return fireLevel;
      case Element.water:
        return waterLevel;
      case Element.nature:
        return natureLevel;
    }
  }

  int get wallHpBonus => wallLevel * 5; // 0/5/10/15
  int get mineCrystalsPerWin => mineLevel * 2; // 0/2/4/6

  int levelOf(BuildingType type) {
    switch (type) {
      case BuildingType.fireForge:
        return fireLevel;
      case BuildingType.waterWell:
        return waterLevel;
      case BuildingType.natureGrove:
        return natureLevel;
      case BuildingType.wall:
        return wallLevel;
      case BuildingType.mine:
        return mineLevel;
    }
  }

  Kingdom upgraded(BuildingType type) {
    final next = levelOf(type) >= 3 ? 3 : levelOf(type) + 1;
    switch (type) {
      case BuildingType.fireForge:
        return copyWith(fireLevel: next);
      case BuildingType.waterWell:
        return copyWith(waterLevel: next);
      case BuildingType.natureGrove:
        return copyWith(natureLevel: next);
      case BuildingType.wall:
        return copyWith(wallLevel: next);
      case BuildingType.mine:
        return copyWith(mineLevel: next);
    }
  }

  Kingdom copyWith({
    int? fireLevel,
    int? waterLevel,
    int? natureLevel,
    int? wallLevel,
    int? mineLevel,
  }) {
    return Kingdom(
      fireLevel: fireLevel ?? this.fireLevel,
      waterLevel: waterLevel ?? this.waterLevel,
      natureLevel: natureLevel ?? this.natureLevel,
      wallLevel: wallLevel ?? this.wallLevel,
      mineLevel: mineLevel ?? this.mineLevel,
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
      elementBonuses: {
        Element.fire: k.fireLevel,
        Element.water: k.waterLevel,
        Element.nature: k.natureLevel,
      },
    );
  }
}
