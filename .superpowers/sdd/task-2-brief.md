### Task 2: Element model and resolution rules

**Files:**
- Create: `lib/engine/element.dart`
- Test: `test/engine/element_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum Element { fire, nature, water }`
  - `const int kElementBonus = 3;`
  - `class ElementRules { static bool beats(Element a, Element b); }` — `true` iff `a` has advantage over `b`.

- [ ] **Step 1: Write the failing test**

`test/engine/element_test.dart`:
```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/element_test.dart`
Expected: FAIL (target of URI doesn't exist / `element.dart` not found).

- [ ] **Step 3: Write minimal implementation**

`lib/engine/element.dart`:
```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engine/element_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/element.dart test/engine/element_test.dart
git commit -m "feat: add element model and advantage rules"
```

---

