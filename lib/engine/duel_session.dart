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

    // Resolve from each side's perspective so both configs apply their own
    // barracks bonus. Damage attribution uses the player-perspective winner.
    final playerView = DuelEngine.resolveRound(
        playerCard: card, opponentCard: oppCard, config: playerConfig);
    final oppView = DuelEngine.resolveRound(
        playerCard: oppCard, opponentCard: card, config: opponentConfig);

    if (playerView.winner == RoundWinner.player) {
      opponentCastleHp -= playerView.damage;
    } else if (oppView.winner == RoundWinner.player) {
      // opponent's own perspective: their card won
      playerCastleHp -= oppView.damage;
    }
    _refill();
    return playerView;
  }

  DuelOutcome get outcome {
    if (opponentCastleHp <= 0) return DuelOutcome.playerWon;
    if (playerCastleHp <= 0) return DuelOutcome.opponentWon;
    final exhausted = _playerHand.isEmpty &&
        _opponentHand.isEmpty &&
        _playerDeck.isEmpty &&
        _opponentDeck.isEmpty;
    if (exhausted) {
      return playerCastleHp >= opponentCastleHp
          ? DuelOutcome.playerWon
          : DuelOutcome.opponentWon;
    }
    return DuelOutcome.ongoing;
  }
}
