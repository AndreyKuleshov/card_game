import 'dart:math';
import '../engine/ability.dart';
import '../engine/ai_controller.dart';
import '../engine/deck.dart';
import '../engine/duel_engine.dart';
import '../engine/duel_session.dart';
import '../engine/game_card.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';

const int kDeckSize = 12;

class MapNode {
  final int index;
  final String title;
  final DuelConfig opponentConfig;
  final bool isBoss;
  final bool isTraining;
  final String? rewardTrumpId;

  const MapNode({
    required this.index,
    required this.title,
    required this.opponentConfig,
    this.isBoss = false,
    this.isTraining = false,
    this.rewardTrumpId,
  });

  /// Opponent tier used for rewards: Противник 1 → 1, Противник 2 → 2, …
  int get level => index;
}

/// Index of the boss node (last in [kSliceNodes]).
int get kBossNodeIndex => kSliceNodes.length - 1;

const kSliceNodes = <MapNode>[
  MapNode(
    index: 0,
    title: 'Тренировка',
    opponentConfig: DuelConfig(startingCastleHp: 20),
    isTraining: true,
  ),
  MapNode(
    index: 1,
    title: 'Противник 1',
    opponentConfig: DuelConfig(startingCastleHp: 28),
  ),
  MapNode(
    index: 2,
    title: 'Противник 2',
    opponentConfig: DuelConfig(startingCastleHp: 34),
  ),
  MapNode(
    index: 3,
    title: 'БОСС: Тыквенный Лорд',
    opponentConfig: DuelConfig(startingCastleHp: 40),
    isBoss: true,
    rewardTrumpId: 'trump_pumpkin_king',
  ),
];

/// Repeats [cards] (in order) until the deck holds [kDeckSize] cards, so a thin
/// card list still fills a full deck. Returns empty if [cards] is empty.
List<GameCard> padToDeck(List<GameCard> cards) {
  final deck = <GameCard>[];
  var i = 0;
  while (deck.length < kDeckSize && cards.isNotEmpty) {
    deck.add(cards[i % cards.length]);
    i++;
  }
  return deck;
}

/// The player's regular draw pile: owned NON-trump cards, padded to a full deck.
/// Trumps are kept out (they live in [buildPlayerTrumps] as once-per-battle
/// plays) so the 4-card hand is always regular cards.
List<GameCard> buildPlayerDeck(SaveState save, List<GameCard> allCards) {
  final owned = allCards
      .where((c) => save.ownedCardIds.contains(c.id) && c.rarity != Rarity.trump)
      .toList();
  return padToDeck(owned);
}

/// The player's owned trumps — each usable once per battle.
List<GameCard> buildPlayerTrumps(SaveState save, List<GameCard> allCards) {
  return allCards
      .where((c) => save.ownedCardIds.contains(c.id) && c.rarity == Rarity.trump)
      .toList();
}

/// Builds an opponent deck weighted toward high power as the node [level] grows
/// (training=0 → mostly weak; boss=3 → mostly strong). Card weight is
/// `power^(1+level)`, so higher levels strongly favour stronger cards. The boss
/// additionally gets a strong trump in its deck. Sampled with [random] so each
/// battle deals different cards.
List<GameCard> buildOpponentDeck({
  required List<GameCard> allCards,
  required int level,
  required bool isBoss,
  required Random random,
  int size = kDeckSize,
}) {
  final pool = allCards.where((c) => c.rarity != Rarity.trump).toList();
  final deck = <GameCard>[];
  if (isBoss) {
    final bossTrump =
        allCards.where((c) => c.id == 'trump_lava_cat').toList();
    deck.addAll(bossTrump);
  }
  if (pool.isEmpty) return deck;

  final exp = 1 + level;
  double weight(GameCard c) => pow(c.power.toDouble(), exp).toDouble();
  final total = pool.fold<double>(0, (s, c) => s + weight(c));

  while (deck.length < size) {
    var r = random.nextDouble() * total;
    var pick = pool.last;
    for (final c in pool) {
      r -= weight(c);
      if (r <= 0) {
        pick = c;
        break;
      }
    }
    deck.add(pick);
  }
  return deck;
}

class DuelReward {
  final int crystalsEarned;
  final bool unlockNext;
  final String? trumpGranted;
  const DuelReward({
    required this.crystalsEarned,
    required this.unlockNext,
    this.trumpGranted,
  });
}

/// Pure computation of what a finished duel grants.
///
/// Base crystals by node type, plus the mine bonus on every win:
///   • тренировка        → 5            (repeatable, no trump chest)
///   • противник (lvl L)  → 10 + 5·L     (+30% trump chest)
///   • босс              → 30           (+ guaranteed rewardTrumpId)
///
/// [unlockNext] advances the frontier only when beating the *current* opponent
/// (the node at the frontier, excluding the boss and training). Pass a
/// caller-owned [random] so chest drops are random in production and
/// deterministic in tests.
DuelReward computeDuelReward({
  required MapNode node,
  required SaveState save,
  required bool won,
  required Random random,
}) {
  if (!won) return const DuelReward(crystalsEarned: 0, unlockNext: false);

  final int base;
  if (node.isTraining) {
    base = 5;
  } else if (node.isBoss) {
    base = 30;
  } else {
    base = 10 + 5 * node.level;
  }
  final earned = base + save.kingdom.mineCrystalsPerWin;

  // Advance only when this is the current opponent (frontier, non-boss).
  final unlockNext = !node.isTraining &&
      !node.isBoss &&
      node.index == save.unlockedNodeIndex;

  String? trump;
  if (node.rewardTrumpId != null) {
    trump = node.rewardTrumpId; // boss
  } else if (!node.isTraining && !node.isBoss && random.nextDouble() < 0.30) {
    trump = 'trump_frost_granny'; // opponent chest
  }
  return DuelReward(crystalsEarned: earned, unlockNext: unlockNext, trumpGranted: trump);
}

DuelSession buildSession({
  required SaveState save,
  required List<GameCard> allCards,
  required MapNode node,
  required Random random,
}) {
  final playerCards = buildPlayerDeck(save, allCards);
  final playerTrumps = buildPlayerTrumps(save, allCards);
  final oppCards = buildOpponentDeck(
    allCards: allCards,
    level: node.level,
    isBoss: node.isBoss,
    random: random,
  );
  return DuelSession(
    playerDeck: Deck(playerCards),
    opponentDeck: Deck(oppCards),
    playerTrumps: playerTrumps,
    playerConfig: KingdomEconomy.toDuelConfig(save.kingdom),
    opponentConfig: node.opponentConfig,
    ai: AiController(),
    random: random,
  )..start();
}
