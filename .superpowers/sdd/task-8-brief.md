### Task 8: Card data — JSON asset and repository

**Files:**
- Create: `assets/cards.json`, `lib/data/card_repository.dart`
- Test: `test/data/card_repository_test.dart`

**Interfaces:**
- Consumes: `GameCard`, `Element`, `Ability`, `Rarity` (Tasks 2–3).
- Produces:
  - `class CardRepository { static GameCard fromJson(Map<String, dynamic> json); static List<GameCard> parseAll(String jsonString); Future<List<GameCard>> loadFromAsset(AssetBundle bundle); }`
  - JSON shape per card: `{"id","name","element":"fire|nature|water","power":int,"rarity":"common|rare|trump","ability":"elementalShift|doubleStrike|shield"|null}`.

- [ ] **Step 1: Create `assets/cards.json` with the slice content**

```json
[
  {"id":"fire_deer","name":"Горячий Олень","element":"fire","power":4,"rarity":"common","ability":null},
  {"id":"fire_rooster","name":"Желанный Петушок","element":"fire","power":6,"rarity":"common","ability":null},
  {"id":"fire_pie","name":"Горелый Пирожок","element":"fire","power":3,"rarity":"common","ability":null},
  {"id":"fire_phoenix_pearl","name":"Перл Феникса","element":"fire","power":7,"rarity":"common","ability":null},
  {"id":"nature_zucchini","name":"Боевой Кабачок","element":"nature","power":5,"rarity":"common","ability":null},
  {"id":"nature_forester","name":"Пьяный Лесник","element":"nature","power":4,"rarity":"common","ability":null},
  {"id":"nature_mushroom","name":"Гриб-Качок","element":"nature","power":6,"rarity":"common","ability":null},
  {"id":"nature_hedgehog","name":"Боевой Ёж","element":"nature","power":3,"rarity":"common","ability":null},
  {"id":"water_jellyfish","name":"Сердитая Медуза","element":"water","power":5,"rarity":"common","ability":null},
  {"id":"water_puddle","name":"Капитан Лужа","element":"water","power":4,"rarity":"common","ability":null},
  {"id":"water_beaver","name":"Бобёр-Сантехник","element":"water","power":6,"rarity":"common","ability":null},
  {"id":"water_dumpling","name":"Ледяной Пельмень","element":"water","power":7,"rarity":"common","ability":null},
  {"id":"trump_pumpkin_king","name":"Король-Тыква","element":"nature","power":9,"rarity":"trump","ability":"doubleStrike"},
  {"id":"trump_lava_cat","name":"Лавовый Котик","element":"fire","power":8,"rarity":"trump","ability":"elementalShift"},
  {"id":"trump_frost_granny","name":"Морозная Бабуля","element":"water","power":9,"rarity":"trump","ability":"shield"},
  {"id":"trump_starter_drake","name":"Дракоша-Стартер","element":"fire","power":8,"rarity":"trump","ability":"doubleStrike"}
]
```

- [ ] **Step 2: Write the failing test**

`test/data/card_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/data/card_repository.dart';
import 'package:card_game/engine/ability.dart';
import 'package:card_game/engine/element.dart';

void main() {
  test('fromJson parses a common card', () {
    final card = CardRepository.fromJson({
      'id': 'fire_deer',
      'name': 'Горячий Олень',
      'element': 'fire',
      'power': 4,
      'rarity': 'common',
      'ability': null,
    });
    expect(card.id, 'fire_deer');
    expect(card.element, Element.fire);
    expect(card.power, 4);
    expect(card.rarity, Rarity.common);
    expect(card.ability, isNull);
  });

  test('fromJson parses a trump card with an ability', () {
    final card = CardRepository.fromJson({
      'id': 'trump_pumpkin_king',
      'name': 'Король-Тыква',
      'element': 'nature',
      'power': 9,
      'rarity': 'trump',
      'ability': 'doubleStrike',
    });
    expect(card.rarity, Rarity.trump);
    expect(card.ability, Ability.doubleStrike);
  });

  test('parseAll reads a list', () {
    const json = '[{"id":"a","name":"A","element":"water","power":5,"rarity":"common","ability":null}]';
    final cards = CardRepository.parseAll(json);
    expect(cards, hasLength(1));
    expect(cards.first.element, Element.water);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/data/card_repository_test.dart`
Expected: FAIL (card_repository.dart not found).

- [ ] **Step 4: Write minimal implementation**

`lib/data/card_repository.dart`:
```dart
import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../engine/ability.dart';
import '../engine/element.dart';
import '../engine/game_card.dart';

class CardRepository {
  const CardRepository._();

  static Element _element(String s) => Element.values.firstWhere((e) => e.name == s);
  static Rarity _rarity(String s) => Rarity.values.firstWhere((e) => e.name == s);
  static Ability? _ability(String? s) =>
      s == null ? null : Ability.values.firstWhere((e) => e.name == s);

  static GameCard fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] as String,
      name: json['name'] as String,
      element: _element(json['element'] as String),
      power: json['power'] as int,
      rarity: _rarity(json['rarity'] as String),
      ability: _ability(json['ability'] as String?),
    );
  }

  static List<GameCard> parseAll(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<GameCard>> loadFromAsset(
      {AssetBundle? bundle, String path = 'assets/cards.json'}) async {
    final b = bundle ?? rootBundle;
    return parseAll(await b.loadString(path));
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/data/card_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add assets/cards.json lib/data/card_repository.dart test/data/card_repository_test.dart
git commit -m "feat: add card json asset and repository parser"
```

---

