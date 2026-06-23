# Task 1: Project setup and dependencies — Report

**Date:** 2026-06-22  
**Branch:** feature/vertical-slice  
**Status:** DONE

## Summary

Successfully scaffolded a Flutter card game project with all required dependencies, folder structure, and configuration. All test suite passes. Project is ready for the next vertical-slice tasks.

## Steps Completed

### Step 1: Create Flutter Project
Command: `flutter create --org com.cardgame --project-name card_game .`
- Flutter 3.44.2 verified on stable channel
- Project scaffold created in the current directory
- Existing `GAME_DESIGN.md` and `docs/` preserved as expected

### Step 2: Add Dependencies
Command: `flutter pub add flutter_riverpod shared_preferences && flutter pub get`
- Added `flutter_riverpod: ^3.3.2`
- Added `shared_preferences: ^2.5.5`
- All transitive dependencies resolved successfully
- pubspec.yaml correctly updated

### Step 3: Register Assets Directory
File: `pubspec.yaml`
- Added `assets:` section under `flutter:`
- Registered `assets/cards.json` for future use
- No validation errors on asset declaration

### Step 4: Create Folder Skeleton
Command: `mkdir -p lib/engine lib/data lib/models lib/state lib/ui assets test/engine test/data test/models test/ui`
- All 9 subdirectories under `lib/` created: engine, data, models, state, ui
- All 4 subdirectories under `test/` created: engine, data, models, ui
- `assets/` directory created

### Step 5: Replace Widget Test with Smoke Test
- Deleted: `test/widget_test.dart`
- Created: `test/setup_smoke_test.dart` with trivial toolchain test
- File content matches brief specification exactly

### Step 6: Run Tests
Command: `flutter test`
- Required: Created placeholder `assets/cards.json` (empty JSON array `[]`)
  - This was necessary because pubspec.yaml declares the asset; Flutter test requires all declared assets to exist
- **Result:** 1 test passing, "All tests passed!"
- Test output: Clean, no warnings or errors

### Step 7: Commit
Command: `git add -A && git commit -m "chore: scaffold flutter project with riverpod and shared_preferences"`
- **Note:** Skipped `git init` and branch creation as per instructions (git already initialized, already on `feature/vertical-slice`)
- Commit hash: `7259eef`
- 157 files committed (scaffold + dependencies + build artifacts)
- Working tree clean after commit

## Verification

1. **Dependencies:** Both `flutter_riverpod` and `shared_preferences` present in pubspec.yaml under dependencies
2. **Assets:** `assets/cards.json` registered and file exists at `/Users/greenolls/cursor/card_game/assets/cards.json`
3. **Folder structure:** All required directories present:
   - lib: engine, data, models, state, ui
   - test: engine, data, models, ui
   - assets: (with cards.json)
4. **Test:** 1/1 passing, output pristine
5. **Git:** Clean working tree, commit recorded on feature/vertical-slice branch

## Concerns

None. All requirements met, no deviations from brief. Project is ready for next tasks.

## Files Created/Modified

- **Created:** pubspec.yaml (via flutter create, then edited)
- **Created:** test/setup_smoke_test.dart
- **Created:** lib/{engine, data, models, state, ui} directories
- **Created:** test/{engine, data, models, ui} directories
- **Created:** assets/cards.json
- **Deleted:** test/widget_test.dart
- **Modified:** pubspec.yaml (added assets declaration and dependencies)

---

**Task Complete:** The project is ready for the next vertical-slice task (UI scaffolding, game engine, state management, etc.).
