import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/models/save_state.dart';
import 'package:card_game/ui/duel_setup.dart';

void main() {
  final base = SaveState.initial(); // frontier = 1, mine bonus = 0
  final training = kSliceNodes.firstWhere((n) => n.isTraining);
  final opp1 = kSliceNodes[1];
  final opp2 = kSliceNodes[2];
  final boss = kSliceNodes[kBossNodeIndex];

  test('loss grants nothing', () {
    final r = computeDuelReward(node: opp1, save: base, won: false, random: Random(0));
    expect(r.crystalsEarned, 0);
    expect(r.unlockNext, isFalse);
    expect(r.trumpGranted, isNull);
  });

  // ── Crystal amounts (mine bonus = 0 on the initial kingdom) ───────────────
  test('training grants 5 + mine bonus', () {
    final r = computeDuelReward(node: training, save: base, won: true, random: Random(0));
    expect(r.crystalsEarned, 5 + base.kingdom.mineCrystalsPerWin);
  });

  test('opponent grants 10 + 5*level + mine bonus', () {
    final r1 = computeDuelReward(node: opp1, save: base, won: true, random: Random(0));
    final r2 = computeDuelReward(node: opp2, save: base, won: true, random: Random(0));
    expect(r1.crystalsEarned, 10 + 5 * opp1.level); // 15
    expect(r2.crystalsEarned, 10 + 5 * opp2.level); // 20
  });

  test('boss grants 30 + mine bonus', () {
    final atBoss = base.copyWith(unlockedNodeIndex: boss.index);
    final r = computeDuelReward(node: boss, save: atBoss, won: true, random: Random(0));
    expect(r.crystalsEarned, 30 + atBoss.kingdom.mineCrystalsPerWin);
  });

  // ── Frontier progression ──────────────────────────────────────────────────
  test('beating the current opponent (frontier) unlocks the next', () {
    final r = computeDuelReward(node: opp1, save: base, won: true, random: Random(0));
    expect(r.unlockNext, isTrue);
  });

  test('training never advances the frontier', () {
    final r = computeDuelReward(node: training, save: base, won: true, random: Random(0));
    expect(r.unlockNext, isFalse);
  });

  test('re-beating an already-cleared opponent does not unlock again', () {
    final ahead = base.copyWith(unlockedNodeIndex: 2);
    final r = computeDuelReward(node: opp1, save: ahead, won: true, random: Random(0));
    expect(r.unlockNext, isFalse);
  });

  test('boss never advances the frontier and grants its trump', () {
    final atBoss = base.copyWith(unlockedNodeIndex: boss.index);
    final r = computeDuelReward(node: boss, save: atBoss, won: true, random: Random(0));
    expect(r.unlockNext, isFalse);
    expect(r.trumpGranted, boss.rewardTrumpId);
    expect(r.trumpGranted, isNotNull);
  });

  // ── Trump chest (opponents only) ───────────────────────────────────────────
  // seed=2 → nextDouble()=0.0007835... (< 0.30) → chest drops trump_frost_granny
  test('opponent chest: seed 2 rolls < 0.30 and grants trump_frost_granny', () {
    final r = computeDuelReward(node: opp1, save: base, won: true, random: Random(2));
    expect(r.trumpGranted, 'trump_frost_granny');
  });

  // seed=0 → nextDouble()=0.8255... (>= 0.30) → no chest drop
  test('opponent chest: seed 0 rolls >= 0.30 and grants no trump', () {
    final r = computeDuelReward(node: opp1, save: base, won: true, random: Random(0));
    expect(r.trumpGranted, isNull);
  });

  test('training never drops a trump chest even on a low roll', () {
    final r = computeDuelReward(node: training, save: base, won: true, random: Random(2));
    expect(r.trumpGranted, isNull);
  });
}
