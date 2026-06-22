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
