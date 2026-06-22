import 'ability.dart';
import 'element.dart';

class GameCard {
  final String id;
  final String name;
  final Element element;
  final int power;
  final Rarity rarity;
  final Ability? ability;

  const GameCard({
    required this.id,
    required this.name,
    required this.element,
    required this.power,
    required this.rarity,
    this.ability,
  });

  @override
  bool operator ==(Object other) => other is GameCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GameCard($id, $name, $element, p$power)';
}
