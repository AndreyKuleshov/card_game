# Art Enhancement Report

**Date:** 2026-06-22  
**Branch:** feature/vertical-slice  
**Status:** DONE

---

## Commits

| SHA | Subject |
|-----|---------|
| `7417404` | feat(ui): add vector art module with CustomPainter widgets |
| `da38b81` | feat(ui/kingdom): wire BuildingArt and CastlePainterView into KingdomScreen |
| `437cd14` | feat(ui/duel): add DuelistPainterView characters and card-play animation |

---

## What Was Built

### lib/ui/art.dart (new, 657 lines)

**CastlePainterView({ double size = 80 })**  
Warm-cartoon castle: sky circle, ground, stone wall with 4 crenellations, gate with plank detail, left + right towers with battlements and window slits, orange flag on the left tower. 4-color flat palette (stone, orange, brown, sky blue).

**BuildingArt({ required BuildingType type, required int level, double size = 56 })**  
- `level == 0` → dashed-rect empty plot with a grey `?` marker and bright ground  
- `barracks` levels 1-3: hall with triangle roof, crosses-arrows symbol; level 3 adds a red flag  
- `wall` levels 1-3: battlemented stone wall growing taller, brick seams, more crenellations per level; level 3 adds blue flag  
- `mine` levels 1-3: arch entrance with dark interior, rail lines, gem crystals (1/2/3); level 3 adds green flag  
- `shouldRepaint` returns true only when `type` or `level` changes; no Random/Date usage

**DuelistPainterView({ required bool isOpponent, double size = 60 })**  
- Hero (isOpponent:false): warm skin, rounded hair, blue torso, friendly smile  
- Villain (isOpponent:true): green skin, spiky hair, dark-green torso, wide grin, small horns  
- `shouldRepaint` returns true only when `isOpponent` changes

---

## Wiring

### kingdom_screen.dart
- Imported `art.dart`
- Added `CastlePainterView(size: 80)` centered header at top of scroll list  
- Removed `_icons` map and `icon` parameter from `_BuildingCard`  
- Replaced `Text(icon, style: TextStyle(fontSize: 36))` with `BuildingArt(type: type, level: level, size: 56)`  
- All titles (Казарма/Стена/Шахта), level pips, effect text, and Построить/Улучшить buttons preserved  
- Создать козырь section preserved and untouched

### duel_screen.dart
- Imported `art.dart`
- `_DuelScreenState` now mixes in `SingleTickerProviderStateMixin`  
- Added `AnimationController` (450ms duration) with two `Tween<double>` animations:  
  - `_playerCardSlide` (1.0 → 0.0): player card slides up from 80px below  
  - `_opponentCardSlide` (-1.0 → 0.0): opponent card slides down from 80px above  
- `_animating` flag disables hand taps during animation  
- Result badge and hint reveal via `_showReveal` trigger after `_cardAnimController.forward()` completes  
- `_OpponentZone`: `DuelistPainterView(isOpponent: true, size: 44)` shown left of opponent HP bar  
- `_PlayerZone`: `DuelistPainterView(isOpponent: false, size: 44)` shown left of player HP bar  
- `_BattleZone`: accepts `playerCardSlide` and `opponentCardSlide` animations as constructor params; uses `AnimatedBuilder` + `Transform.translate` + `Opacity` for the slide effect  
- All existing logic preserved: power-breakdown hint, бьёт element line, HpBars with «Замок» labels, `GameCardView` hand, outcome → RewardScreen navigation

---

## Test & Analyze Results

```
flutter analyze: No issues found!
flutter test: 59/59 passed
```

---

## Concerns

- **Overflow**: `DuelistPainterView` at 44px fits comfortably in the HP bar row via `Row + Expanded`; `GameCardView` hand remains in a `SingleChildScrollView` so narrow screens scroll horizontally. No RenderFlex overflow expected at 360px.  
- **Art polish**: The CustomPainter art is bold and readable at intended sizes (44-80px) but is purely geometric/flat; fine for a warm-cartoon style. Crystals use a `RadialGradient` for a subtle 3-D feel.  
- **Animation timing**: Slide-in is 450ms; badge reveal is immediate after that with 400ms elasticOut scale. Total feel is ~850ms per round which matches the existing 900ms `Future.delayed` before navigation — no race condition.  
- **Engine files**: Untouched (zero diff on lib/engine/*).

---

## Village Scene Rebuild (2026-06-22) — ce3788d

Replaced the list-based KingdomScreen body with a village scene layout:

- `_MeadowPainter`: sky gradient + rounded-rect green meadow + dirt path + decorative flowers.
- `_VillageScene` (`Stack` + `LayoutBuilder`): `CastlePainterView` centred at top, three `_PositionedBuilding` widgets at distinct positions (barracks upper-left, mine upper-right, wall front-centre).
- Selection: `AnimatedScale` + orange glow `BoxShadow` + coloured label background; defaults to barracks so the panel is never empty.
- `_UpgradePanel` bottom card replaces `_BuildingCard`; scrollable via `SingleChildScrollView`.
- `_CraftSection` unchanged in behaviour; shown persistently when `barracksLevel >= 3`.
- Scene capped at 520 px wide, height 58 % of available (min 180, max 320) — safe at 360 px.
- `findsOneWidget` → `findsWidgets` in kingdom_screen_test.dart (titles appear in scene label + panel).
- `flutter analyze`: No issues. `flutter test`: 59/59 passed.

---

## Village Scene — Cozy Environment Enrichment (2026-06-23) — 6037c73

Scene footprint enlarged to 600×400px max (was 520×320); height share raised to 62% of available.

### `_MeadowPainter` additions (all in `lib/ui/kingdom_screen.dart`):
- **Clouds**: 3 fluffy blob clusters drawn in the sky gradient (deterministic positions).
- **Dirt road network**: curved quadratic-bezier paths from the castle gate to each of the three buildings; warm sandy `Color(0xFFD4A96A)` with a lighter inner-highlight stripe.
- **Pond**: bottom-right corner, blue oval with radial gradient + shimmer arc + green rim.
- **Fence segments**: two short picket-fence rows at lower left and lower right edges; pointed posts + two horizontal rails.
- **Trees**: 6 trees at plot edges — layered dark/mid/light green foliage blobs + brown trunk with shadow stripe; back-row trees are smaller for depth.
- **Bushes**: 4 bushes (3-blob overlapping circles) scattered between buildings and trees.
- **Flowers**: 10 5-petal flowers alternating yellow and pink, spread across the meadow floor; precomputed trig (`_cos5`/`_sin5` constants — no `math.dart` or Random).

### Constraints honoured:
- No overflow at 360 px: scene centred in `Center`; buildings use `Stack(clipBehavior: Clip.hardEdge)`; labels wrapped in `FittedBox`.
- Deterministic painting: all positions hardcoded or derived from loop index.
- `shouldRepaint` unchanged (returns false — painter is stateless).
- Engine files untouched.
- `flutter analyze`: No issues found! `flutter test`: 59/59 passed.
