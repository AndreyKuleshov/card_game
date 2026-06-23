import 'dart:math';
import 'ai_controller.dart';
import 'deck.dart';
import 'duel_engine.dart';
import 'game_card.dart';

enum DuelOutcome { playerWon, opponentWon, ongoing }

/// Turn-based duel: the opponent reveals a card first ([pendingOpponentCard]),
/// then the player answers with one card via [respond] — a card from the 4-card
/// hand OR one of the [availableTrumps] (each trump usable once per battle).
class DuelSession {
  final Deck _playerDeck;
  final Deck _opponentDeck;
  final DuelConfig playerConfig;
  final DuelConfig opponentConfig;
  final AiController ai;
  final Random random;

  final List<GameCard> _playerHand = [];
  final List<GameCard> _opponentHand = [];
  final List<GameCard> _trumps = []; // each usable once per battle

  GameCard? _pendingOpponentCard;

  late int playerCastleHp;
  late int opponentCastleHp;

  DuelSession({
    required Deck playerDeck,
    required Deck opponentDeck,
    required List<GameCard> playerTrumps,
    required this.playerConfig,
    required this.opponentConfig,
    required this.ai,
    required this.random,
  })  : _playerDeck = playerDeck,
        _opponentDeck = opponentDeck {
    _trumps.addAll(playerTrumps);
  }

  List<GameCard> get playerHand => List.unmodifiable(_playerHand);
  List<GameCard> get opponentHand => List.unmodifiable(_opponentHand);

  /// Owned trumps not yet spent this battle. Each can be played once via
  /// [respond]; they return next battle (the session is rebuilt from scratch).
  List<GameCard> get availableTrumps => List.unmodifiable(_trumps);

  /// The card the opponent has played and the player must answer.
  GameCard? get pendingOpponentCard => _pendingOpponentCard;

  void start() {
    _playerDeck.shuffle(random);
    _opponentDeck.shuffle(random);
    playerCastleHp = playerConfig.startingCastleHp;
    opponentCastleHp = opponentConfig.startingCastleHp;
    _playerHand.clear();
    _opponentHand.clear();
    _fill(_playerDeck, _playerHand, playerConfig.handSize);
    _fill(_opponentDeck, _opponentHand, opponentConfig.handSize);
    _revealOpponentCard();
  }

  // Opponent leads each round: top the reserve back up to a full hand, then
  // pick a card to reveal. With recycling the deck never empties, so there is
  // always one card on the table plus `handSize - 1` in reserve.
  void _revealOpponentCard() {
    _fill(_opponentDeck, _opponentHand, opponentConfig.handSize);
    if (_opponentHand.isEmpty) {
      _pendingOpponentCard = null;
      return;
    }
    final c = ai.chooseCard(hand: _opponentHand, config: opponentConfig);
    _opponentHand.remove(c);
    _pendingOpponentCard = c;
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

  /// Player answers [pendingOpponentCard] with [card] (a hand card or a trump).
  /// Resolves the clash, applies castle damage, consumes the card (hand refills
  /// to 4; a trump is spent for the battle), then the opponent reveals its next
  /// card. Returns the resolved round (player perspective).
  RoundResult respond(GameCard card) {
    final oppCard = _pendingOpponentCard!;
    final wasTrump = _trumps.remove(card); // GameCard equality is by id
    if (!wasTrump) {
      _playerHand.remove(card);
    }

    final result = DuelEngine.resolveRound(
        playerCard: card, opponentCard: oppCard, config: playerConfig);
    if (result.winner == RoundWinner.player) {
      opponentCastleHp -= result.damage;
    } else if (result.winner == RoundWinner.opponent) {
      playerCastleHp -= result.damage;
    }

    if (!wasTrump) {
      _fill(_playerDeck, _playerHand, playerConfig.handSize);
    }
    _revealOpponentCard();
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
