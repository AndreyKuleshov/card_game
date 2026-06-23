import 'ability.dart';
import 'element.dart';
import 'game_card.dart';

class DuelConfig {
  final int startingCastleHp;
  final int handSize;

  /// Per-element power bonus from the player's elemental forges
  /// (🔥 Зажигалка / 💧 Полторашка / 🌿 Травка). Applied to the player side for
  /// a card whose element matches. Empty for opponents.
  final Map<Element, int> elementBonuses;

  const DuelConfig({
    this.startingCastleHp = 30,
    this.handSize = 4,
    this.elementBonuses = const {},
  });
}

enum RoundWinner { player, opponent, tie }

class RoundResult {
  final RoundWinner winner;
  final int damage;
  final int playerEffectivePower;
  final int opponentEffectivePower;
  final GameCard playerCard;
  final GameCard opponentCard;

  const RoundResult({
    required this.winner,
    required this.damage,
    required this.playerEffectivePower,
    required this.opponentEffectivePower,
    required this.playerCard,
    required this.opponentCard,
  });
}

class DuelEngine {
  const DuelEngine._();

  static int effectivePower({
    required GameCard card,
    required GameCard opponentCard,
    required bool isPlayer,
    required DuelConfig config,
  }) {
    var power = card.power;
    final opponentShifts = opponentCard.ability == Ability.elementalShift;
    if (!opponentShifts && ElementRules.beats(card.element, opponentCard.element)) {
      power += kElementBonus;
    }
    if (isPlayer) {
      power += config.elementBonuses[card.element] ?? 0;
    }
    return power;
  }

  static RoundResult resolveRound({
    required GameCard playerCard,
    required GameCard opponentCard,
    required DuelConfig config,
  }) {
    final pPow = effectivePower(
        card: playerCard, opponentCard: opponentCard, isPlayer: true, config: config);
    final oPow = effectivePower(
        card: opponentCard, opponentCard: playerCard, isPlayer: false, config: config);

    if (pPow == oPow) {
      return RoundResult(
          winner: RoundWinner.tie,
          damage: 0,
          playerEffectivePower: pPow,
          opponentEffectivePower: oPow,
          playerCard: playerCard,
          opponentCard: opponentCard);
    }

    final playerWins = pPow > oPow;
    final winningCard = playerWins ? playerCard : opponentCard;
    final losingCard = playerWins ? opponentCard : playerCard;

    var damage = (pPow - oPow).abs();
    if (winningCard.ability == Ability.doubleStrike) {
      damage = (damage * 1.5).floor();
    }
    if (losingCard.ability == Ability.shield) {
      damage = 0;
    }

    return RoundResult(
      winner: playerWins ? RoundWinner.player : RoundWinner.opponent,
      damage: damage,
      playerEffectivePower: pPow,
      opponentEffectivePower: oPow,
      playerCard: playerCard,
      opponentCard: opponentCard,
    );
  }
}
