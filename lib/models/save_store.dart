import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'save_state.dart';

class SaveStore {
  static const _key = 'save_v1';

  Future<SaveState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return SaveState.initial();
    return SaveState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(SaveState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
