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
    _playerHand.addAll(_playerDeck.drawUpTo(playerConfig.handSize - _playerHand.length));
    _opponentHand
        .addAll(_opponentDeck.drawUpTo(opponentConfig.handSize - _opponentHand.length));
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
    if (opponentCastleHp <= 0) return DuelOutcome.playerWon;
    if (playerCastleHp <= 0) return DuelOutcome.opponentWon;
    // A round needs both sides to field a card (hands are refilled after each
    // round). If either side can no longer play, the duel resolves by castle HP
    // — higher wins, ties favor the player.
    if (_playerHand.isEmpty || _opponentHand.isEmpty) {
      return playerCastleHp >= opponentCastleHp
          ? DuelOutcome.playerWon
          : DuelOutcome.opponentWon;
    }
    return DuelOutcome.ongoing;
  }
}
