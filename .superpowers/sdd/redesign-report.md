# Warm Cartoon Redesign — Implementation Report

## Commits

| SHA | Subject |
|---|---|
| `c89e46b` | feat(engine): add playerCard/opponentCard to RoundResult |
| `831d395` | feat(ui): add warm-cartoon design system (theme + reusable widgets) |
| `88c76bb` | feat(ui): warm cartoon redesign + duel round-result reveal |

---

## Engine Change

**File:** `lib/engine/duel_engine.dart`

`RoundResult` gained two new required fields:
```dart
final GameCard playerCard;
final GameCard opponentCard;
```
Both are populated from the `playerCard`/`opponentCard` params already present in `resolveRound`. This is additive — no existing engine tests assert `RoundResult` construction, so all 9 tests remained green without modification.

---

## Design System

### `lib/ui/theme.dart` — `GameColors`

| Member | Purpose |
|---|---|
| `backgroundStops` | Warm parchment gradient (amber50 → orange100) for menu screens |
| `tabletopStops` | Soft green-felt gradient (green300 → green700) for the duel |
| `elementColor(ge.Element)` | Per-element Color: fire=deep-orange, nature=green, water=lightBlue |
| `elementEmoji(ge.Element)` | 🔥 / 🌿 / 💧 |
| `elementName(ge.Element)` | Огонь / Природа / Вода |
| `cardRadius` | 16 px |
| `chipRadius` | 20 px |
| `warmTheme()` | Material3 ThemeData seeded from orange700; bold fontWeights, no external font assets |

**Note:** `ge.Element` is imported as a prefixed alias (`import '../engine/element.dart' as ge`) to avoid the `Element` name collision with Flutter's own `Element` class from `framework.dart`.

### `lib/ui/widgets.dart` — Reusable Widgets

| Widget | Constructor | Key behaviours |
|---|---|---|
| `GameCardView` | `({required GameCard card, double width=88, bool highlighted=false, bool dimmed=false, VoidCallback? onTap})` | Rounded card with element gradient band, large element emoji, FittedBox-wrapped name (no overflow), circular power badge (bottom-right), ⭐ if `rarity==trump`. Highlighted: amber glow + border + 1.06 scale. Dimmed: 0.45 opacity. |
| `CardBack` | `({double width=88})` | Face-down card with indigo gradient and 🛡️ crest. |
| `HpBar` | `({required int current, required int max, required String label, required Color color})` | 🏰 icon + label + `current/max` text + AnimatedContainer fill bar. Fill clamped to [0,1]; text in white for visibility on tabletop gradient. |
| `CrystalChip` | `({required int amount})` | Light-blue pill showing `💎 N`. Used in AppBar actions. |

---

## Screen Changes

### `lib/ui/app.dart`
Applied `GameColors.warmTheme()` — replaces the old `deepPurple` seed.

### `lib/ui/world_map_screen.dart`
- Warm parchment `Container` gradient body.
- `CrystalChip` in AppBar actions; castle 🏰 emoji IconButton replaces the material castle icon.
- Nodes rendered as custom `_NodeCard` (Material + InkWell with borderRadius) instead of generic `Card > ListTile`. Boss nodes tinted amber. Locked nodes grey with 🔒. Unlocked nodes show «играть ▶».
- Node icons: 🚩 normal, 🔥 boss.

### `lib/ui/kingdom_screen.dart`
- Warm gradient body.
- `CrystalChip` in AppBar.
- Each building in `_BuildingCard`: large icon (🏹/🧱/⛏️), title, `_LevelPips` (●●○ in amber/grey), effect text, «Улучшить (N💎)» button disabled when unaffordable or maxed.
- «Создать козырь» moved to a dedicated `_CraftSection` card with 🔮 icon. `_CraftSection` accepts typed `SaveState` and `SaveController` (not `dynamic`) for type safety.
- Preserved exact text: «Казарма», «Стена», «Шахта», «Создать козырь (40💎)».

### `lib/ui/reward_screen.dart`
- Converted to `ConsumerWidget` so it can watch `cardsProvider`.
- Trump name lookup: `cardsProvider.value` (Riverpod v3 `AsyncValue.value` getter, nullable) — falls back to raw id if not yet loaded or not found.
- Layout: gradient body, Card centered with big 🎉/💥 emoji, «Победа!»/«Поражение» headline, `CrystalChip`, amber «🏆 Новый козырь: <name>» box, «В королевство» FilledButton.

### `lib/ui/duel_screen.dart`
Full tabletop redesign with three zones:

**TOP — `_OpponentZone`**
- `HpBar` for «Замок врага» (red fill).
- Row of `CardBack(width:52)` widgets matching `session.opponentHand.length` — player sees how many cards the AI has, but not which ones.

**CENTER — `_BattleZone`**
- Before first move: «Выбери карту, чтобы атаковать» hint in white.
- After each round: player card (left) + result badge (center) + opponent card (right), all revealed with animation:
  - Player card: `AnimatedOpacity` 0→1 (300ms).
  - Badge: `AnimatedScale` 0.6→1.0 with `Curves.elasticOut` (400ms).
  - Opponent card: `AnimatedScale` 0→1.0 with `Curves.elasticOut` (450ms) — the "flip reveal".
  - Element hint: `AnimatedOpacity` below the row (500ms).
- Winner card `highlighted`, loser card `dimmed`.
- Badge colour: green for win, red for loss, white for tie.
- Element hint text: «🔥 бьёт 🌿 +N» or «🔥 vs 💧 — Ничья!».

**BOTTOM — `_PlayerZone`**
- `HpBar` for «Твой замок» (blue fill).
- Horizontally scrollable row of `GameCardView` — taps disabled once duel is resolved.

**Reveal flow:** tap → `setState(_showReveal=false)` → `addPostFrameCallback(_showReveal=true)` so the transition always triggers. Duel finish is delayed 900ms to let the last reveal animation play before navigating.

---

## Overflow Mitigations

| Risk | Mitigation |
|---|---|
| Long card names | `FittedBox(fit: BoxFit.scaleDown)` inside `Flexible` in `GameCardView` |
| Many hand cards at narrow width | `SingleChildScrollView(scrollDirection: Axis.horizontal)` in `_PlayerZone` and `_OpponentZone` |
| Long HP labels | `Text(overflow: TextOverflow.ellipsis)` inside `Flexible` in `HpBar` |
| Reward card content | `SingleChildScrollView` wrapping the centered `Card` body |

---

## Test & Analyze Results

```
flutter analyze → No issues found! (4.0s)
flutter test    → All tests passed! (57 tests across engine + UI suites)
```

UI test updates:
- `test/ui/duel_screen_test.dart`: `find.byType(Card)` → `find.byType(GameCardView)` (meaningful assertion on the new hand widget).
- All other UI test assertions preserved verbatim: «Карта мира», «Тренировка», «БОСС», «Казарма», «Стена», «Шахта», «Создать козырь», «Замок».
