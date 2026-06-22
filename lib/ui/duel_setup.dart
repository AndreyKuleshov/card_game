import 'dart:math';
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
  final String? rewardTrumpId;

  const MapNode({
    required this.index,
    required this.title,
    required this.opponentCardIds,
    required this.opponentConfig,
    this.isBoss = false,
    this.rewardTrumpId,
  });
}

const kSliceNodes = <MapNode>[
  MapNode(
    index: 0,
    title: 'Тренировка',
    opponentCardIds: ['fire_pie', 'nature_hedgehog', 'water_puddle', 'fire_deer'],
    opponentConfig: DuelConfig(startingCastleHp: 20),
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

/// Builds a 12-card deck from owned cards, padding by repeating owned ids so a
/// thin starter collection still fills a deck.
List<GameCard> buildPlayerDeck(SaveState save, List<GameCard> allCards) {
  final owned = allCards.where((c) => save.ownedCardIds.contains(c.id)).toList();
  final deck = <GameCard>[];
  var i = 0;
  while (deck.length < kDeckSize && owned.isNotEmpty) {
    deck.add(owned[i % owned.length]);
    i++;
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

/// Pure, deterministic computation of what a finished duel grants.
/// Mirrors the slice rules: crystals = 5 + mine bonus; unlock the next node
/// only when this node is the current frontier and not the last; a boss grants
/// its rewardTrumpId; a non-boss win rolls a seeded ~30% chest for a trump.
DuelReward computeDuelReward({
  required MapNode node,
  required SaveState save,
  required bool won,
}) {
  if (!won) return const DuelReward(crystalsEarned: 0, unlockNext: false);
  final earned = 5 + save.kingdom.mineCrystalsPerWin;
  final unlockNext =
      node.index >= save.unlockedNodeIndex && node.index < kSliceNodes.length - 1;
  String? trump;
  if (node.rewardTrumpId != null) {
    trump = node.rewardTrumpId;
  } else if (Random(node.index + 7).nextDouble() < 0.30) {
    trump = 'trump_frost_granny';
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
  final oppCards = node.opponentCardIds.map((id) => byId[id]!).toList();
  return DuelSession(
    playerDeck: Deck(playerCards),
    opponentDeck: Deck(oppCards),
    playerConfig: KingdomEconomy.toDuelConfig(save.kingdom),
    opponentConfig: node.opponentConfig,
    ai: AiController(),
    random: random,
  )..start();
}
