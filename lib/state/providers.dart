import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/card_repository.dart';
import '../engine/game_card.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';
import '../models/save_store.dart';

final saveStoreProvider = Provider<SaveStore>((ref) => SaveStore());

final cardsProvider = FutureProvider<List<GameCard>>((ref) async {
  return CardRepository.loadFromAsset();
});

final saveStateProvider =
    NotifierProvider<SaveController, SaveState>(SaveController.new);

class SaveController extends Notifier<SaveState> {
  late final SaveStore _store;

  @override
  SaveState build() {
    _store = ref.read(saveStoreProvider);
    return SaveState.initial();
  }

  Future<void> hydrate() async {
    state = await _store.load();
  }

  void _commit(SaveState next) {
    state = next;
    _store.save(next);
  }

  void addCrystals(int n) => _commit(state.copyWith(crystals: state.crystals + n));

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
