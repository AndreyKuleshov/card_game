import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/duel_session.dart';
import '../engine/game_card.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'reward_screen.dart';

class DuelScreen extends ConsumerStatefulWidget {
  final MapNode node;
  const DuelScreen({super.key, required this.node});

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  DuelSession? _session;
  String _log = 'Выбери карту';
  bool _resolved = false;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsProvider);
    final save = ref.watch(saveStateProvider);

    return cardsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Ошибка: $e'))),
      data: (allCards) {
        final session = _session ??= buildSession(
          save: save,
          allCards: allCards,
          node: widget.node,
          random: Random(widget.node.index + 1),
        );
        return Scaffold(
          appBar: AppBar(title: Text(widget.node.title)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Замок врага: ${session.opponentCastleHp}'),
                Text('Твой Замок: ${session.playerCastleHp}'),
                const SizedBox(height: 12),
                Text(_log),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final card in session.playerHand)
                      Card(
                        child: InkWell(
                          onTap: _resolved ? null : () => _play(card, session),
                          child: SizedBox(
                            width: 80,
                            height: 110,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_elementEmoji(card),
                                      style: const TextStyle(fontSize: 22)),
                                  Flexible(
                                    child: Text(card.name,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 10)),
                                  ),
                                  Text('${card.power}',
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _elementEmoji(GameCard c) =>
      {'fire': '🔥', 'nature': '🌿', 'water': '💧'}[c.element.name] ?? '❔';

  void _play(GameCard card, DuelSession session) {
    final result = session.playPlayerCard(card);
    setState(() {
      _log = 'Раунд: ${result.playerEffectivePower} против '
          '${result.opponentEffectivePower}, урон ${result.damage}';
    });
    final outcome = session.outcome;
    if (outcome != DuelOutcome.ongoing && !_resolved) {
      _resolved = true;
      _finish(outcome == DuelOutcome.playerWon);
    } else {
      setState(() {}); // refresh hand
    }
  }

  void _finish(bool won) {
    final controller = ref.read(saveStateProvider.notifier);
    final save = ref.read(saveStateProvider);
    final reward = computeDuelReward(node: widget.node, save: save, won: won, random: Random());
    if (won) {
      if (reward.crystalsEarned > 0) controller.addCrystals(reward.crystalsEarned);
      if (reward.unlockNext) controller.unlockNextNode();
      if (reward.trumpGranted != null) controller.grantCard(reward.trumpGranted!);
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => RewardScreen(
        won: won,
        crystalsEarned: reward.crystalsEarned,
        trumpGranted: reward.trumpGranted,
      ),
    ));
  }
}
