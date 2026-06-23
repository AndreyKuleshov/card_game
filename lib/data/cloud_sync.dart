import 'package:shared_preferences/shared_preferences.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';
import 'api_client.dart';

const _keyToken = 'cloud_token';
const _keyPlayerId = 'cloud_player_id';
const _keyLocalUpdatedAt = 'local_updated_at';

const int _schemaVersion = 1;

class CloudSync {
  final ApiClient _api;

  CloudSync({ApiClient? api}) : _api = api ?? ApiClient();

  Future<void> ensurePlayer() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyToken) != null) return;
    try {
      final credentials = await _api.createPlayer();
      await prefs.setString(_keyToken, credentials.token);
      await prefs.setString(_keyPlayerId, credentials.playerId);
    } catch (_) {
      // best-effort
    }
  }

  Future<SaveState> pullAndMerge(SaveState local) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) return local;

    try {
      final remote = await _api.getProgress(token);
      if (remote == null) return local;

      final localUpdatedAtMs = prefs.getInt(_keyLocalUpdatedAt);
      final localUpdatedAt = localUpdatedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(localUpdatedAtMs)
          : DateTime.fromMillisecondsSinceEpoch(0);
      final cloudIsNewer = remote.updatedAt.isAfter(localUpdatedAt);

      final cloudState = SaveState.fromJson(remote.data);
      return mergeProgress(
        local: local,
        cloud: cloudState,
        cloudIsNewer: cloudIsNewer,
      );
    } catch (_) {
      return local;
    }
  }

  Future<void> push(SaveState s) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) return;

    try {
      await _api.putProgress(
        token,
        data: s.toJson(),
        crystals: s.crystals,
        schemaVersion: _schemaVersion,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_keyLocalUpdatedAt, now);
    } catch (_) {
      // best-effort
    }
  }
}

SaveState mergeProgress({
  required SaveState local,
  required SaveState cloud,
  required bool cloudIsNewer,
}) {
  final mergedCardIds = {...local.ownedCardIds, ...cloud.ownedCardIds};
  final mergedNodeIndex = local.unlockedNodeIndex > cloud.unlockedNodeIndex
      ? local.unlockedNodeIndex
      : cloud.unlockedNodeIndex;
  final mergedKingdom = Kingdom(
    fireLevel: local.kingdom.fireLevel > cloud.kingdom.fireLevel
        ? local.kingdom.fireLevel
        : cloud.kingdom.fireLevel,
    waterLevel: local.kingdom.waterLevel > cloud.kingdom.waterLevel
        ? local.kingdom.waterLevel
        : cloud.kingdom.waterLevel,
    natureLevel: local.kingdom.natureLevel > cloud.kingdom.natureLevel
        ? local.kingdom.natureLevel
        : cloud.kingdom.natureLevel,
    wallLevel: local.kingdom.wallLevel > cloud.kingdom.wallLevel
        ? local.kingdom.wallLevel
        : cloud.kingdom.wallLevel,
    mineLevel: local.kingdom.mineLevel > cloud.kingdom.mineLevel
        ? local.kingdom.mineLevel
        : cloud.kingdom.mineLevel,
  );
  final mergedCrystals = cloudIsNewer ? cloud.crystals : local.crystals;

  return SaveState(
    crystals: mergedCrystals,
    kingdom: mergedKingdom,
    ownedCardIds: mergedCardIds,
    unlockedNodeIndex: mergedNodeIndex,
  );
}
