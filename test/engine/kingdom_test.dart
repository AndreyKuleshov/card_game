import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/kingdom.dart';

void main() {
  test('default kingdom is all unbuilt (level 0) with fire barracks', () {
    const k = Kingdom();
    expect(k.barracksLevel, 0);
    expect(k.wallLevel, 0);
    expect(k.mineLevel, 0);
    expect(k.barracksElement, Element.fire);
  });

  test('unbuilt buildings give no bonus', () {
    const k = Kingdom();
    expect(k.barracksBonus, 0);
    expect(k.wallHpBonus, 0);
    expect(k.mineCrystalsPerWin, 0);
  });

  test('building from level 0 costs 5; default config has no bonuses', () {
    expect(KingdomEconomy.upgradeCost(BuildingType.wall, 0), 5);
    final cfg = KingdomEconomy.toDuelConfig(const Kingdom());
    expect(cfg.startingCastleHp, 30); // 30 base + 0 wall
    expect(cfg.barracksBonus, 0);
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
