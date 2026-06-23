import '../models/save_state.dart';

abstract class ProgressRepository {
  Future<SaveState?> load();
  Future<void> save(SaveState state);
}
