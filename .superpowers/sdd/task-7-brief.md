### Task 7: Kingdom — buildings, upgrades, economy

**Files:**
- Create: `lib/engine/kingdom.dart`
- Test: `test/engine/kingdom_test.dart`

**Interfaces:**
- Consumes: `Element`, `DuelConfig` (Tasks 2, 5).
- Produces:
  - `enum BuildingType { barracks, wall, mine }`
  - `class Kingdom { final int barracksLevel, wallLevel, mineLevel; final Element barracksElement; const Kingdom({...defaults all level 1, barracksElement = Element.fire}); Kingdom copyWith({...}); }`
  - Effect getters: `int get barracksBonus` (level→ +1/+2/+3), `int get wallHpBonus` (+5/+10/+15), `int get mineCrystalsPerWin` (+2/+4/+6).
  - `int levelOf(BuildingType)`, `Kingdom upgraded(BuildingType)` (caps at level 3).
  - `class KingdomEconomy { static int upgradeCost(BuildingType type, int currentLevel); static DuelConfig toDuelConfig(Kingdom k); }` — cost table `{1->10, 2->25}` (cost to go *from* that level), `toDuelConfig` maps wall/barracks bonuses into a `DuelConfig`.

- [ ] **Step 1: Write the failing test**

`test/engine/kingdom_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/kingdom.dart';

void main() {
  test('default kingdom is all level 1 with fire barracks', () {
    const k = Kingdom();
    expect(k.barracksLevel, 1);
    expect(k.wallLevel, 1);
    expect(k.mineLevel, 1);
    expect(k.barracksElement, Element.fire);
  });

  test('building effects scale with level', () {
    const k = Kingdom(barracksLevel: 1, wallLevel: 2, mineLevel: 3);
    expect(k.barracksBonus, 1);
    expect(k.wallHpBonus, 10);
    expect(k.mineCrystalsPerWin, 6);
  });

  test('upgrading increments level and caps at 3', () {
    var k = const Kingdom(barracksLevel: 2);
    k = k.upgraded(BuildingType.barracks);
    expect(k.barracksLevel, 3);
    k = k.upgraded(BuildingType.barracks);
    expect(k.barracksLevel, 3); // capped
  });

  test('upgrade cost table', () {
    expect(KingdomEconomy.upgradeCost(BuildingType.wall, 1), 10);
    expect(KingdomEconomy.upgradeCost(BuildingType.wall, 2), 25);
  });

  test('toDuelConfig maps wall hp and barracks bonus', () {
    const k = Kingdom(barracksLevel: 3, wallLevel: 2, barracksElement: Element.water);
    final cfg = KingdomEconomy.toDuelConfig(k);
    expect(cfg.startingCastleHp, 40); // 30 base + 10 wall
    expect(cfg.barracksElement, Element.water);
    expect(cfg.barracksBonus, 3);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/kingdom_test.dart`
Expected: FAIL (kingdom.dart not found).

- [ ] **Step 3: Write minimal implementation**

`lib/engine/kingdom.dart`:
```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engine/kingdom_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/kingdom.dart test/engine/kingdom_test.dart
git commit -m "feat: add kingdom buildings, upgrades, and economy"
```

---

