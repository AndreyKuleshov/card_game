import 'dart:async' show unawaited;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/card_repository.dart';
import '../data/cloud_sync.dart';
import '../data/local_progress_repository.dart';
import '../engine/game_card.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';
import '../models/save_store.dart';

final saveStoreProvider = Provider<SaveStore>((ref) => SaveStore());

final localProgressRepoProvider =
    Provider<LocalProgressRepository>((ref) => LocalProgressRepository());

final cloudSyncProvider = Provider<CloudSync>((ref) => CloudSync());

final cardsProvider = FutureProvider<List<GameCard>>((ref) async {
  return CardRepository.loadFromAsset();
});

final saveStateProvider =
    NotifierProvider<SaveController, SaveState>(SaveController.new);

class SaveController extends Notifier<SaveState> {
  late final LocalProgressRepository _repo;
  late final CloudSync _cloud;

  @override
  SaveState build() {
    _repo = ref.read(localProgressRepoProvider);
    _cloud = ref.read(cloudSyncProvider);
    return SaveState.initial();
  }

  Future<void> hydrate() async {
    final local = await _repo.load() ?? SaveState.initial();
    state = local;

    try {
      await _cloud.ensurePlayer();
      final merged = await _cloud.pullAndMerge(local);
      state = merged;
      await _repo.save(merged);
      await _cloud.push(merged);
    } catch (_) {
      // best-effort: local state remains
    }
  }

  void _commit(SaveState next) {
    state = next;
    // instant local save
    unawaited(_repo.save(next));
    // best-effort cloud push (fire-and-forget; CloudSync handles failures)
    unawaited(_cloud.push(next));
  }

  void addCrystals(int n) =>
      _commit(state.copyWith(crystals: state.crystals + n));

  bool tryUpgrade(BuildingType type) {
    final level = state.kingdom.levelOf(type);
    if (level >= 3) return false;
    final cost = KingdomEconomy.upgradeCost(type, level);
    if (state.crystals < cost) return false;
    _commit(state.copyWith(
      crystals: state.crystals - cost,
      kingdom: state.kingdom.upgraded(type),
    ));
    return true;
  }

  void grantCard(String id) {
    if (state.ownedCardIds.contains(id)) return;
    _commit(state.copyWith(ownedCardIds: {...state.ownedCardIds, id}));
  }

  void unlockNextNode() =>
      _commit(state.copyWith(unlockedNodeIndex: state.unlockedNodeIndex + 1));
}
