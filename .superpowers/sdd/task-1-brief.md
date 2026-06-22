### Task 1: Project setup and dependencies

**Files:**
- Create: `pubspec.yaml` (via `flutter create`, then edit)
- Create: folder skeleton under `lib/` and `test/`
- Test: `test/setup_smoke_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: a runnable Flutter project with `flutter_riverpod` and `shared_preferences` available; `flutter test` green.

- [ ] **Step 1: Create the Flutter project in the current directory**

Run:
```bash
cd /Users/greenolls/cursor/card_game
flutter create --org com.cardgame --project-name card_game .
```
Expected: project scaffold created; `flutter --version` shows a stable channel.

- [ ] **Step 2: Add dependencies**

Run:
```bash
flutter pub add flutter_riverpod shared_preferences
flutter pub get
```
Expected: `pubspec.yaml` lists `flutter_riverpod` and `shared_preferences` under `dependencies`; pub get succeeds.

- [ ] **Step 3: Register the assets directory in `pubspec.yaml`**

Under the `flutter:` section add:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/cards.json
```

- [ ] **Step 4: Create folder skeleton**

Run:
```bash
mkdir -p lib/engine lib/data lib/models lib/state lib/ui assets test/engine test/data test/models test/ui
```

- [ ] **Step 5: Replace the default widget test with a smoke test**

Delete `test/widget_test.dart` and create `test/setup_smoke_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toolchain is wired up', () {
    expect(1 + 1, 2);
  });
}
```

- [ ] **Step 6: Run tests**

Run: `flutter test`
Expected: PASS (1 test).

- [ ] **Step 7: Commit**

```bash
git init
git add -A
git commit -m "chore: scaffold flutter project with riverpod and shared_preferences"
```

---

