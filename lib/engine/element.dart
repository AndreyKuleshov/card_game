/// The three fantasy elements. Cycle: fire -> nature -> water -> fire.
enum Element { fire, nature, water }

/// Bonus added to effective power when a card has elemental advantage.
const int kElementBonus = 3;

class ElementRules {
  const ElementRules._();

  /// Returns true if [a] has elemental advantage over [b].
  static bool beats(Element a, Element b) {
    switch (a) {
      case Element.fire:
        return b == Element.nature;
      case Element.nature:
        return b == Element.water;
      case Element.water:
        return b == Element.fire;
    }
  }
}
