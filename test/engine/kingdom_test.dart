import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/kingdom.dart';

void main() {
  test('default kingdom has all levels at 0', () {
    const k = Kingdom();
    expect(k.fireLevel, 0);
    expect(k.waterLevel, 0);
    expect(k.natureLevel, 0);
    expect(k.wallLevel, 0);
    expect(k.mineLevel, 0);
  });

  test('unbuilt buildings give no bonus', () {
    const k = Kingdom();
    expect(k.elementBonus(Element.fire), 0);
    expect(k.elementBonus(Element.water), 0);
    expect(k.elementBonus(Element.nature), 0);
    expect(k.wallHpBonus, 0);
    expect(k.mineCrystalsPerWin, 0);
  });

  test('building from level 0 costs 5; default config has no bonuses', () {
    expect(KingdomEconomy.upgradeCost(BuildingType.wall, 0), 5);
    final cfg = KingdomEconomy.toDuelConfig(const Kingdom());
    expect(cfg.startingCastleHp, 30); // 30 base + 0 wall
    expect(cfg.elementBonuses[Element.fire], 0);
    expect(cfg.elementBonuses[Element.water], 0);
    expect(cfg.elementBonuses[Element.nature], 0);
  });

  test('building effects scale with level', () {
    const k = Kingdom(fireLevel: 1, waterLevel: 2, natureLevel: 3, wallLevel: 2, mineLevel: 3);
    expect(k.elementBonus(Element.fire), 1);
    expect(k.elementBonus(Element.water), 2);
    expect(k.elementBonus(Element.nature), 3);
    expect(k.wallHpBonus, 10);
    expect(k.mineCrystalsPerWin, 6);
  });

  test('upgrading increments level and caps at 3', () {
    var k = const Kingdom(fireLevel: 2);
    k = k.upgraded(BuildingType.fireForge);
    expect(k.fireLevel, 3);
    k = k.upgraded(BuildingType.fireForge);
    expect(k.fireLevel, 3); // capped
  });

  test('upgrade cost table', () {
    expect(KingdomEconomy.upgradeCost(BuildingType.wall, 1), 10);
    expect(KingdomEconomy.upgradeCost(BuildingType.wall, 2), 25);
  });

  test('toDuelConfig maps wall hp and forge bonuses', () {
    const k = Kingdom(fireLevel: 2, waterLevel: 1, natureLevel: 3, wallLevel: 2);
    final cfg = KingdomEconomy.toDuelConfig(k);
    expect(cfg.startingCastleHp, 40); // 30 base + 10 wall
    expect(cfg.elementBonuses[Element.fire], 2);
    expect(cfg.elementBonuses[Element.water], 1);
    expect(cfg.elementBonuses[Element.nature], 3);
  });
}
