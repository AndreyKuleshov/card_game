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
  final List<String> opponentCardIds;
  final DuelConfig opponentConfig;
  final bool isBoss;
  final bool isTraining;
  final String? rewardTrumpId;

  const MapNode({
    required this.index,
    required this.title,
    required this.opponentCardIds,
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
    opponentCardIds: ['fire_pie', 'nature_hedgehog', 'water_puddle', 'fire_deer'],
    opponentConfig: DuelConfig(startingCastleHp: 20),
    isTraining: true,
  ),
  MapNode(
    index: 1,
    title: 'Противник 1',
    opponentCardIds: ['fire_rooster', 'nature_zucchini', 'water_jellyfish', 'nature_mushroom'],
    opponentConfig: DuelConfig(startingCastleHp: 28),
  ),
  MapNode(
    index: 2,
    title: 'Противник 2',
    opponentCardIds: ['water_beaver', 'fire_phoenix_pearl', 'nature_mushroom', 'water_dumpling'],
    opponentConfig: DuelConfig(startingCastleHp: 34),
  ),
  MapNode(
    index: 3,
    title: 'БОСС: Тыквенный Лорд',
    opponentCardIds: ['water_dumpling', 'fire_phoenix_pearl', 'water_beaver', 'trump_lava_cat'],
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

/// Builds a 12-card deck from the player's owned cards. Trumps are placed first
/// so owned козыри are always included (they live at the end of cards.json and
/// would otherwise be cut off when padding to the deck size).
List<GameCard> buildPlayerDeck(SaveState save, List<GameCard> allCards) {
  final owned = allCards.where((c) => save.ownedCardIds.contains(c.id)).toList();
  final trumps = owned.where((c) => c.rarity == Rarity.trump).toList();
  final others = owned.where((c) => c.rarity != Rarity.trump).toList();
  return padToDeck([...trumps, ...others]);
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
  final byId = {for (final c in allCards) c.id: c};
  final playerCards = buildPlayerDeck(save, allCards);
  // Pad the opponent's themed card list up to a full deck so duels last as long
  // as the player's (they no longer run out after a few rounds).
  final oppCards =
      padToDeck(node.opponentCardIds.map((id) => byId[id]!).toList());
  return DuelSession(
    playerDeck: Deck(playerCards),
    opponentDeck: Deck(oppCards),
    playerConfig: KingdomEconomy.toDuelConfig(save.kingdom),
    opponentConfig: node.opponentConfig,
    ai: AiController(),
    random: random,
  )..start();
}
