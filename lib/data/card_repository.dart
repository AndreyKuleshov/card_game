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
