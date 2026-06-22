import 'dart:math';
import 'ai_controller.dart';
import 'deck.dart';
import 'duel_engine.dart';
import 'game_card.dart';

enum DuelOutcome { playerWon, opponentWon, ongoing }

class DuelSession {
  final Deck _playerDeck;
  final Deck _opponentDeck;
  final DuelConfig playerConfig;
  final DuelConfig opponentConfig;
  final AiController ai;
  final Random random;

  final List<GameCard> _playerHand = [];
  final List<GameCard> _opponentHand = [];

  late int playerCastleHp;
  late int opponentCastleHp;

  DuelSession({
    required Deck playerDeck,
    required Deck opponentDeck,
    required this.playerConfig,
    required this.opponentConfig,
    required this.ai,
    required this.random,
  })  : _playerDeck = playerDeck,
        _opponentDeck = opponentDeck;

  List<GameCard> get playerHand => List.unmodifiable(_playerHand);
  List<GameCard> get opponentHand => List.unmodifiable(_opponentHand);

  void start() {
    _playerDeck.shuffle(random);
    _opponentDeck.shuffle(random);
    playerCastleHp = playerConfig.startingCastleHp;
    opponentCastleHp = opponentConfig.startingCastleHp;
    _playerHand.clear();
    _opponentHand.clear();
    _refill();
  }

  void _refill() {
    _fill(_playerDeck, _playerHand, playerConfig.handSize);
    _fill(_opponentDeck, _opponentHand, opponentConfig.handSize);
  }

  // Draw up to [handSize], reshuffling the deck when it empties so cards never
  // permanently run out — the duel ends only when a castle is destroyed.
  void _fill(Deck deck, List<GameCard> hand, int handSize) {
    while (hand.length < handSize) {
      if (deck.isEmpty) {
        if (deck.isExhaustible) break; // empty source deck: nothing to draw
        deck.recycle(random);
      }
      final drawn = deck.drawUpTo(handSize - hand.length);
      if (drawn.isEmpty) break;
      hand.addAll(drawn);
    }
  }

  RoundResult playPlayerCard(GameCard card) {
    _playerHand.remove(card);
    final oppCard = ai.chooseCard(hand: _opponentHand, config: opponentConfig);
    _opponentHand.remove(oppCard);

    // Single authoritative resolution from the player's perspective so the
    // returned RoundResult and the castle-damage attribution never disagree.
    final result = DuelEngine.resolveRound(
        playerCard: card, opponentCard: oppCard, config: playerConfig);
    if (result.winner == RoundWinner.player) {
      opponentCastleHp -= result.damage;
    } else if (result.winner == RoundWinner.opponent) {
      playerCastleHp -= result.damage;
    }
    _refill();
    return result;
  }

  DuelOutcome get outcome {
    // The duel ends ONLY when a castle is destroyed. Decks recycle (see _fill),
    // so cards never permanently run out.
    if (opponentCastleHp <= 0) return DuelOutcome.playerWon;
    if (playerCastleHp <= 0) return DuelOutcome.opponentWon;
    return DuelOutcome.ongoing;
  }
}
