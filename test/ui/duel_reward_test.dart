import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/models/save_state.dart';
import 'package:card_game/ui/duel_setup.dart';

void main() {
  final base = SaveState.initial();

  test('loss grants nothing', () {
    final r = computeDuelReward(node: kSliceNodes[0], save: base, won: false, random: Random(0));
    expect(r.crystalsEarned, 0);
    expect(r.unlockNext, isFalse);
    expect(r.trumpGranted, isNull);
  });

  test('win grants 5 + mine bonus crystals', () {
    final r = computeDuelReward(node: kSliceNodes[0], save: base, won: true, random: Random(0));
    expect(r.crystalsEarned, 5 + base.kingdom.mineCrystalsPerWin);
  });

  test('winning the frontier node unlocks the next', () {
    final r = computeDuelReward(node: kSliceNodes[0], save: base, won: true, random: Random(0));
    expect(r.unlockNext, isTrue);
  });

  test('winning the last (boss) node does not unlock past the end and grants its trump', () {
    final boss = kSliceNodes.last;
    final atBoss = base.copyWith(unlockedNodeIndex: boss.index);
    final r = computeDuelReward(node: boss, save: atBoss, won: true, random: Random(0));
    expect(r.unlockNext, isFalse);
    expect(r.trumpGranted, boss.rewardTrumpId);
    expect(r.trumpGranted, isNotNull);
  });

  test('re-winning an already-cleared node does not unlock again', () {
    final ahead = base.copyWith(unlockedNodeIndex: 2);
    final r = computeDuelReward(node: kSliceNodes[0], save: ahead, won: true, random: Random(0));
    expect(r.unlockNext, isFalse);
  });

  // seed=2 → nextDouble()=0.0007835... (< 0.30) → chest drops trump_frost_granny
  test('chest drop: seed 2 rolls < 0.30 and grants trump_frost_granny', () {
    final r = computeDuelReward(
        node: kSliceNodes[1], save: base, won: true, random: Random(2));
    expect(r.trumpGranted, 'trump_frost_granny');
  });

  // seed=0 → nextDouble()=0.8255... (>= 0.30) → no chest drop
  test('chest drop: seed 0 rolls >= 0.30 and grants no trump', () {
    final r = computeDuelReward(
        node: kSliceNodes[1], save: base, won: true, random: Random(0));
    expect(r.trumpGranted, isNull);
  });
}
