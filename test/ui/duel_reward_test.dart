import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/models/save_state.dart';
import 'package:card_game/ui/duel_setup.dart';

void main() {
  final base = SaveState.initial();

  test('loss grants nothing', () {
    final r = computeDuelReward(node: kSliceNodes[0], save: base, won: false);
    expect(r.crystalsEarned, 0);
    expect(r.unlockNext, isFalse);
    expect(r.trumpGranted, isNull);
  });

  test('win grants 5 + mine bonus crystals', () {
    final r = computeDuelReward(node: kSliceNodes[0], save: base, won: true);
    expect(r.crystalsEarned, 5 + base.kingdom.mineCrystalsPerWin);
  });

  test('winning the frontier node unlocks the next', () {
    final r = computeDuelReward(node: kSliceNodes[0], save: base, won: true);
    expect(r.unlockNext, isTrue);
  });

  test('winning the last (boss) node does not unlock past the end and grants its trump', () {
    final boss = kSliceNodes.last;
    final atBoss = base.copyWith(unlockedNodeIndex: boss.index);
    final r = computeDuelReward(node: boss, save: atBoss, won: true);
    expect(r.unlockNext, isFalse);
    expect(r.trumpGranted, boss.rewardTrumpId);
    expect(r.trumpGranted, isNotNull);
  });

  test('re-winning an already-cleared node does not unlock again', () {
    final ahead = base.copyWith(unlockedNodeIndex: 2);
    final r = computeDuelReward(node: kSliceNodes[0], save: ahead, won: true);
    expect(r.unlockNext, isFalse);
  });

  test('chest roll is deterministic for a given node', () {
    final a = computeDuelReward(node: kSliceNodes[1], save: base, won: true);
    final b = computeDuelReward(node: kSliceNodes[1], save: base, won: true);
    expect(a.trumpGranted, b.trumpGranted); // same seed -> same outcome
  });
}
