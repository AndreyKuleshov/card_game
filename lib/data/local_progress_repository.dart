import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/save_state.dart';
import 'progress_repository.dart';

class LocalProgressRepository implements ProgressRepository {
  static const _key = 'save_v2';

  @override
  Future<SaveState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return SaveState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(SaveState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
