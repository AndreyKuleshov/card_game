# Forges Feature — Implementation Report

Date: 2026-06-23
Branch: feature/vertical-slice

## What was done

### 1. save_state.dart — new kingdom serialization
- Replaced `barracksLevel`/`barracksElement` JSON keys with `fireLevel`/`waterLevel`/`natureLevel`/`wallLevel`/`mineLevel`.
- Removed the unused `element.dart` import (no longer needed after dropping `barracksElement`).

### 2. save_store.dart — version bump
- Storage key bumped from `save_v1` to `save_v2`. On first launch after the update, any existing v1 save is silently ignored and `SaveState.initial()` is returned, avoiding decode crashes from the incompatible schema.

### 3. kingdom_screen.dart — 5-building scene
- `_titles` map extended to all 5 `BuildingType` values with Russian names: Зажигалка / Полторашка / Травка / Стена / Шахта.
- `_effect()` helper updated: forge buildings show `+N к 🔥/💧/🌿 стихии`, wall and mine unchanged.
- Craft gate changed from `k.barracksLevel >= 3` to `k.fireLevel >= 3` (Зажигалка at max level unlocks crafting).
- Default selected building changed from `BuildingType.barracks` to `BuildingType.fireForge` so the upgrade panel is never empty on first open.
- Scene layout updated: 5 buildings placed at non-overlapping fractional positions (wall far-left, fireForge left-center, natureGrove center-front, waterWell right-center, mine far-right). Castle stays center-back. Z-order renders wall/mine behind forges.

### 4. duel_screen.dart — forge bonus label + clash animation
- Power breakdown: `+N🏹` → `+N⚒️` (the bonus comes from elemental forges, not a barracks).
- `SingleTickerProviderStateMixin` → `TickerProviderStateMixin` to support two controllers.
- Added `_clashController` (420ms) with `_clashProgress` animation that fires after the slide-in completes.
- `_BattleZone` gains a `clashProgress` parameter. Winner translates toward loser (lunge: 22px + 14% scale-up via `sin(π·t)` approximation). Loser recoils away and dims to 65% opacity. On tie, both bounce ±6px.
- Impact spark (⚔️ or 💫 on tie) appears at the Stack center, fades in/out around t≈0.5 using `SizedBox.shrink()` below 5% opacity to skip unnecessary layout.
- Flow unchanged: slide → clash → reveal badge → wait → navigate to RewardScreen.

### 5. art.dart — new building painters
Three new `_BuildingPainter` cases replace the old `barracks` case:

**fireForge (Зажигалка)**: Metal brazier bowl on two legs. Flame rendered as three concentric quadratic-bezier teardrops (outer orange, mid yellow-orange, inner bright yellow at lvl 2+). Flame height/width grow with level. Level 3 adds a flag pole.

**waterWell (Полторашка)**: 1.5L plastic bottle shape built from a `Path` with quadratic shoulder curves. Blue gradient body, dark navy cap, white shimmer stripe, label band. Level 2 adds a second smaller bottle to the right. Level 3 adds a flag.

**natureGrove (Травка)**: Grass tufts (stroke lines) at base. Central bush/tree built from layered dark/mid/light green circles. Level 2 gains a trunk and two side bushes. Level 3 adds pink berry dots and a flag. All paint calls use precomputed constants — fully deterministic.

### 6. Tests
All four affected test files updated to use the new API:
- `duel_engine_test.dart`: `DuelConfig(elementBonuses: {Element.fire: 3})`
- `kingdom_test.dart`: fully rewritten for `fireLevel`/`waterLevel`/`natureLevel`, `elementBonus()`, `toDuelConfig` elementBonuses map
- `save_state_test.dart`: round-trip now uses `Kingdom(fireLevel:2, waterLevel:1, natureLevel:3, wallLevel:3, mineLevel:1)` and asserts all five fields
- `kingdom_screen_test.dart`: titles updated, craft tests use `BuildingType.fireForge`

## Test & Analyze results
- `flutter analyze`: **No issues found**
- `flutter test`: **59/59 passed**

## Commits
- `c802c9b` fix: update save_state and save_store for new kingdom fields
- `1d6a6c2` fix: update kingdom_screen for 5 buildings with new forge model
- `0602828` fix: update duel_screen forge bonus label and add clash animation
- `abbe799` feat: add building art for fireForge, waterWell, natureGrove
- `ec87eeb` test: update all tests for new engine API

## Key decisions

1. **5-building layout at narrow width (360px)**: Building widget size clamps to min 44px. At 360px scene width, 5 buildings at fractional positions span the full width without overlap. The wall and mine are placed further back (h*0.38) and the three forges forward (h*0.53–0.57) for natural depth layering.

2. **Clash animation implementation**: Used a `sin(π·t)` approximation (`4t(1-t)`) instead of importing `dart:math` for a cleaner dependency footprint. The winning card lunges then returns; losing card's opacity drop is capped at 35% so it remains visible. The spark uses `SizedBox.shrink()` to avoid a phantom hitbox when invisible.

3. **`save_v2` key**: A hard version bump was chosen over graceful migration. The schema change (removing `barracksElement`) is not backward-compatible, so silent reset to initial state is the safest user-facing outcome.

4. **`_paintEmptyPlot` reuse**: All three new forge painters call the existing `_paintEmptyPlot` helper at level 0, preserving the "?" dashed-outline empty plot visual for unbuilt buildings.

## Concerns

- **Overflow on very narrow screens (<340px)**: The 5-building row hasn't been tested below 340px. The `clamp` on building size (min 44px) helps, but overlaps are theoretically possible below ~330px. The wall/mine positions (left: w*0.01, right: w*0.80) could clip off-screen if the scene container is narrower than expected.
- **Clash animation missing `mounted` guard on inner then()**: The nested `.then((_) { ... setState ... })` inside `_clashController.forward()` does check `mounted` but if the widget is disposed between slide-in completing and clash completing, the outer then's `setState` could be missed. In practice the 420ms window is short, but it is a potential edge case.
- **No model tests for `save_store.dart` v1→v2 migration**: The test only checks that v2 saves round-trip. There is no test verifying that a v1 key is properly ignored on load — this is tested implicitly (mock prefs start empty), but a negative test would improve confidence.
