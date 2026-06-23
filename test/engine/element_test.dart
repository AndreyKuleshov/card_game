import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';

void main() {
  group('ElementRules.beats', () {
    test('fire beats nature', () {
      expect(ElementRules.beats(Element.fire, Element.nature), isTrue);
    });
    test('nature beats water', () {
      expect(ElementRules.beats(Element.nature, Element.water), isTrue);
    });
    test('water beats fire', () {
      expect(ElementRules.beats(Element.water, Element.fire), isTrue);
    });
    test('relationship is not symmetric', () {
      expect(ElementRules.beats(Element.nature, Element.fire), isFalse);
      expect(ElementRules.beats(Element.water, Element.nature), isFalse);
      expect(ElementRules.beats(Element.fire, Element.water), isFalse);
    });
    test('same element has no advantage', () {
      expect(ElementRules.beats(Element.fire, Element.fire), isFalse);
    });
  });

  test('element bonus is 3', () {
    expect(kElementBonus, 3);
  });
}
