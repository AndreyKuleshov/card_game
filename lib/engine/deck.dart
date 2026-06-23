import 'dart:math';
import 'game_card.dart';

class Deck {
  final List<GameCard> _cards;
  final List<GameCard> _original;

  Deck(List<GameCard> cards)
      : _cards = List.of(cards),
        _original = List.of(cards);

  int get remaining => _cards.length;
  bool get isEmpty => _cards.isEmpty;
  bool get isExhaustible => _original.isEmpty;

  GameCard? draw() => _cards.isEmpty ? null : _cards.removeAt(0);

  /// Refill the draw pile from a reshuffled copy of the original cards. Lets a
  /// duel keep going (cards never permanently run out) so it ends only when a
  /// castle falls. No-op if the deck was created empty.
  void recycle(Random random) {
    if (_original.isEmpty) return;
    _cards
      ..clear()
      ..addAll(_original)
      ..shuffle(random);
  }

  List<GameCard> drawUpTo(int n) {
    final out = <GameCard>[];
    for (var i = 0; i < n; i++) {
      final card = draw();
      if (card == null) break;
      out.add(card);
    }
    return out;
  }

  void shuffle(Random random) => _cards.shuffle(random);
}
