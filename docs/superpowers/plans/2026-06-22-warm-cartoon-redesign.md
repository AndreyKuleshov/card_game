# Flutter Card Game — Warm Cartoon Redesign + Duel UX Fix

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply a "ламповый мультяшный" (warm friendly cartoon) visual skin across all four screens and fix the duel screen so players can see the opponent's card and the round result.

**Architecture:** Add two `GameCard` fields to `RoundResult` (engine-only change, no Flutter imports); create `lib/ui/theme.dart` (palette/helpers) and `lib/ui/widgets.dart` (reusable game widgets); rewrite the four UI screens; update UI widget tests; leave all engine logic and tests untouched.

**Tech Stack:** Flutter 3.x / Dart, Riverpod v3, flutter_test, shared_preferences mock.

## Global Constraints

- `lib/engine/` must remain Flutter-free (no `package:flutter` imports).
- No external font assets, no network fonts, no image assets — colors/gradients/emoji/fontWeight only.
- Russian UI text, humorous card names (e.g. «Горелый Пирожок», «Боевой Кабачок»).
- No overflow at 360–420 px logical width.
- `flutter analyze` → "No issues found!"; `flutter test` → all green.
- Preserve these exact text strings in tests: «Карта мира», «Тренировка», «БОСС», «Казарма», «Стена», «Шахта», «Создать козырь», «Замок».
- Conventional Commits; trailer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Do NOT run `flutter run`.

---

## File Map

| Path | Action | Responsibility |
|---|---|---|
| `lib/engine/duel_engine.dart` | Modify | Add `playerCard`/`opponentCard` to `RoundResult` |
| `lib/ui/theme.dart` | Create | `GameColors`, element helpers, text styles |
| `lib/ui/widgets.dart` | Create | `GameCardView`, `CardBack`, `HpBar`, `CrystalChip` |
| `lib/ui/app.dart` | Modify | Apply warm `ThemeData` |
| `lib/ui/duel_screen.dart` | Modify | Full tabletop redesign with round-result reveal |
| `lib/ui/world_map_screen.dart` | Modify | Warm background, friendly node cards |
| `lib/ui/kingdom_screen.dart` | Modify | Building cards with icons and styled buttons |
| `lib/ui/reward_screen.dart` | Modify | Celebratory card + trump name lookup |
| `test/engine/duel_engine_test.dart` | Modify | Pass `playerCard`/`opponentCard` in assertions |
| `test/ui/duel_screen_test.dart` | Modify | `GameCardView` instead of `Card` |

---

## Task 1: Engine — extend RoundResult with card references

**Files:**
- Modify: `lib/engine/duel_engine.dart`
- Test: `test/engine/duel_engine_test.dart`

**Interfaces:**
- Produces: `RoundResult.playerCard: GameCard`, `RoundResult.opponentCard: GameCard` (required constructor params)

- [ ] **Step 1: Add fields to RoundResult**

In `lib/engine/duel_engine.dart` change:

```dart
class RoundResult {
  final RoundWinner winner;
  final int damage;
  final int playerEffectivePower;
  final int opponentEffectivePower;
  final GameCard playerCard;
  final GameCard opponentCard;

  const RoundResult({
    required this.winner,
    required this.damage,
    required this.playerEffectivePower,
    required this.opponentEffectivePower,
    required this.playerCard,
    required this.opponentCard,
  });
}
```

- [ ] **Step 2: Populate fields in resolveRound**

Both `return RoundResult(...)` calls inside `resolveRound` must add:
```dart
playerCard: playerCard,
opponentCard: opponentCard,
```

- [ ] **Step 3: Run engine tests — expect compile error first**

```bash
cd /Users/greenolls/cursor/card_game && flutter test test/engine/duel_engine_test.dart
```
Expected: compile error "Too few positional arguments" (tests don't pass the new fields yet).

- [ ] **Step 4: Update engine tests to pass the new fields**

Every `DuelEngine.resolveRound(...)` call in the test already passes `playerCard:` and `opponentCard:` — they're named params. The new fields are on the *result*, not the call site, so no test changes are needed for the call sites. But the tests may still fail if `RoundResult` construction is asserted somewhere. Check: the tests only assert `r.winner`, `r.damage` — no `RoundResult(...)` constructors in test code. So the tests should compile and pass once step 2 is done.

Run:
```bash
cd /Users/greenolls/cursor/card_game && flutter test test/engine/duel_engine_test.dart
```
Expected: All 9 tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/greenolls/cursor/card_game && git add lib/engine/duel_engine.dart && git commit -m "$(cat <<'EOF'
feat(engine): add playerCard/opponentCard to RoundResult

Expose the cards played each round so the duel UI can show both
the player's and opponent's card side-by-side after each round.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Design system — theme.dart + widgets.dart

**Files:**
- Create: `lib/ui/theme.dart`
- Create: `lib/ui/widgets.dart`

**Interfaces:**
- Produces:
  - `GameColors.background` (warm cream gradient stops)
  - `GameColors.tabletop` (soft green felt gradient stops)
  - `GameColors.elementColor(Element) → Color`
  - `GameColors.elementEmoji(Element) → String`
  - `GameColors.elementName(Element) → String`
  - `GameColors.warmTheme() → ThemeData`
  - `GameCardView({required GameCard card, double width=88, bool highlighted=false, bool dimmed=false, VoidCallback? onTap})`
  - `CardBack({double width=88})`
  - `HpBar({required int current, required int max, required String label, required Color color})`
  - `CrystalChip({required int amount})`

- [ ] **Step 1: Create theme.dart**

Create `/Users/greenolls/cursor/card_game/lib/ui/theme.dart`:

```dart
import 'package:flutter/material.dart';
import '../engine/element.dart';

/// Centralised palette and helpers for the warm-cartoon visual theme.
class GameColors {
  GameColors._();

  // ── Background gradients ──────────────────────────────────────────────────

  /// Warm parchment/cream gradient for menu screens.
  static const List<Color> backgroundStops = [
    Color(0xFFFFF8E1), // amber50
    Color(0xFFFFE0B2), // orange100
  ];

  /// Soft green-felt gradient for the duel tabletop.
  static const List<Color> tabletopStops = [
    Color(0xFF81C784), // green300
    Color(0xFF388E3C), // green700
  ];

  // ── Element colours ───────────────────────────────────────────────────────

  static Color elementColor(Element e) {
    switch (e) {
      case Element.fire:
        return const Color(0xFFE64A19); // deep-orange700
      case Element.nature:
        return const Color(0xFF388E3C); // green700
      case Element.water:
        return const Color(0xFF0288D1); // lightBlue700
    }
  }

  static String elementEmoji(Element e) {
    switch (e) {
      case Element.fire:   return '🔥';
      case Element.nature: return '🌿';
      case Element.water:  return '💧';
    }
  }

  static String elementName(Element e) {
    switch (e) {
      case Element.fire:   return 'Огонь';
      case Element.nature: return 'Природа';
      case Element.water:  return 'Вода';
    }
  }

  // ── Shapes ────────────────────────────────────────────────────────────────

  static const double cardRadius = 16;
  static const double chipRadius = 20;

  // ── ThemeData ─────────────────────────────────────────────────────────────

  /// Warm amber-based Material 3 theme. No custom font assets — uses
  /// fontWeight and letterSpacing to achieve a bold rounded feel.
  static ThemeData warmTheme() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFFF57C00), // orange700
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: base,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFFF8E1),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF57C00),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        color: const Color(0xFFFFFDE7),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        headlineSmall: TextStyle(fontWeight: FontWeight.w800),
        titleLarge:    TextStyle(fontWeight: FontWeight.w700),
        titleMedium:   TextStyle(fontWeight: FontWeight.w600),
        bodyMedium:    TextStyle(fontWeight: FontWeight.w400),
        labelSmall:    TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.3),
      ),
    );
  }
}
```

- [ ] **Step 2: Create widgets.dart**

Create `/Users/greenolls/cursor/card_game/lib/ui/widgets.dart`:

```dart
import 'package:flutter/material.dart';
import '../engine/ability.dart';
import '../engine/game_card.dart';
import 'theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GameCardView
// ─────────────────────────────────────────────────────────────────────────────

/// A tappable card tile with element gradient, name, power badge and rarity
/// star. [highlighted] adds a golden glow; [dimmed] lowers opacity.
class GameCardView extends StatelessWidget {
  final GameCard card;
  final double width;
  final bool highlighted;
  final bool dimmed;
  final VoidCallback? onTap;

  const GameCardView({
    super.key,
    required this.card,
    this.width = 88,
    this.highlighted = false,
    this.dimmed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final elColor = GameColors.elementColor(card.element);
    final cardHeight = width * 1.35;

    Widget content = Container(
      width: width,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GameColors.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            elColor.withAlpha(200),
            const Color(0xFFFFFDE7),
          ],
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: Colors.amber.withAlpha(200),
                  blurRadius: 14,
                  spreadRadius: 3,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
        border: highlighted
            ? Border.all(color: Colors.amber, width: 2.5)
            : null,
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Element emoji
                Text(
                  GameColors.elementEmoji(card.element),
                  style: TextStyle(fontSize: width * 0.30),
                  textAlign: TextAlign.center,
                ),
                // Card name — never overflows
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      card.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Power badge (bottom-right)
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: elColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${card.power}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          // Trump star (top-right)
          if (card.rarity == Rarity.trump)
            const Positioned(
              top: 4,
              right: 4,
              child: Text('⭐', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );

    // Dim inactive cards
    if (dimmed) {
      content = Opacity(opacity: 0.45, child: content);
    }

    // Animate highlight scale
    if (highlighted) {
      content = Transform.scale(scale: 1.06, child: content);
    }

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CardBack
// ─────────────────────────────────────────────────────────────────────────────

/// Face-down card showing a decorative back (patterned gradient + crest emoji).
class CardBack extends StatelessWidget {
  final double width;

  const CardBack({super.key, this.width = 88});

  @override
  Widget build(BuildContext context) {
    final height = width * 1.35;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GameColors.cardRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C6BC0), Color(0xFF283593)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '🛡️',
          style: TextStyle(fontSize: width * 0.38),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HpBar
// ─────────────────────────────────────────────────────────────────────────────

/// Animated castle HP bar. Fill is clamped to [0,1].
class HpBar extends StatelessWidget {
  final int current;
  final int max;
  final String label;
  final Color color;

  const HpBar({
    super.key,
    required this.current,
    required this.max,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (max > 0 ? current / max : 0.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🏰', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$label  $current/$max',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CrystalChip
// ─────────────────────────────────────────────────────────────────────────────

/// A pill widget showing a crystal count: 💎 N.
class CrystalChip extends StatelessWidget {
  final int amount;

  const CrystalChip({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(GameColors.chipRadius),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Text(
        '💎 $amount',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify no analyze errors introduced**

```bash
cd /Users/greenolls/cursor/card_game && flutter analyze lib/ui/theme.dart lib/ui/widgets.dart
```
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
cd /Users/greenolls/cursor/card_game && git add lib/ui/theme.dart lib/ui/widgets.dart && git commit -m "$(cat <<'EOF'
feat(ui): add warm-cartoon design system (theme + reusable widgets)

GameColors palette, element helpers, warmTheme(); reusable GameCardView,
CardBack, HpBar, and CrystalChip widgets for the ламповый cartoon look.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Apply theme in app.dart

**Files:**
- Modify: `lib/ui/app.dart`

**Interfaces:**
- Consumes: `GameColors.warmTheme()` from `lib/ui/theme.dart`

- [ ] **Step 1: Update app.dart**

```dart
import 'package:flutter/material.dart';
import 'theme.dart';
import 'world_map_screen.dart';

class CardGameApp extends StatelessWidget {
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Карточное Королевство',
      debugShowCheckedModeBanner: false,
      theme: GameColors.warmTheme(),
      home: const WorldMapScreen(),
    );
  }
}
```

- [ ] **Step 2: Run app smoke test**

```bash
cd /Users/greenolls/cursor/card_game && flutter test test/ui/app_smoke_test.dart
```
Expected: 1 test passes.

---

## Task 4: Redesign world_map_screen.dart

**Files:**
- Modify: `lib/ui/world_map_screen.dart`

**Interfaces:**
- Consumes: `CrystalChip` from widgets.dart
- Must contain: «Карта мира», «Тренировка», «БОСС»

- [ ] **Step 1: Rewrite world_map_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'duel_screen.dart';
import 'kingdom_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class WorldMapScreen extends ConsumerWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта мира'),
        actions: [
          CrystalChip(amount: save.crystals),
          const SizedBox(width: 8),
          IconButton(
            icon: const Text('🏰', style: TextStyle(fontSize: 22)),
            tooltip: 'Королевство',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KingdomScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GameColors.backgroundStops,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final node in kSliceNodes)
              _NodeCard(node: node, unlocked: node.index <= save.unlockedNodeIndex),
          ],
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final MapNode node;
  final bool unlocked;

  const _NodeCard({required this.node, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: unlocked
            ? (node.isBoss ? const Color(0xFFFFE0B2) : Colors.white)
            : Colors.grey.shade200,
        elevation: unlocked ? 4 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: unlocked
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DuelScreen(node: node)),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  node.isBoss ? '🔥' : '🚩',
                  style: TextStyle(
                    fontSize: 28,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: unlocked ? null : Colors.grey,
                    ),
                  ),
                ),
                unlocked
                    ? const Text('играть ▶',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF57C00),
                        ))
                    : const Text('🔒',
                        style: TextStyle(fontSize: 20, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run world map test**

```bash
cd /Users/greenolls/cursor/card_game && flutter test test/ui/world_map_test.dart
```
Expected: 1 test passes («Карта мира», «Тренировка», «БОСС» all found).

---

## Task 5: Redesign kingdom_screen.dart

**Files:**
- Modify: `lib/ui/kingdom_screen.dart`

**Interfaces:**
- Consumes: `CrystalChip` from widgets.dart
- Must contain: «Казарма», «Стена», «Шахта», «Создать козырь»

- [ ] **Step 1: Rewrite kingdom_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/kingdom.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets.dart';

class KingdomScreen extends ConsumerWidget {
  const KingdomScreen({super.key});

  static const _titles = {
    BuildingType.barracks: 'Казарма',
    BuildingType.wall: 'Стена',
    BuildingType.mine: 'Шахта',
  };

  static const _icons = {
    BuildingType.barracks: '🏹',
    BuildingType.wall: '🧱',
    BuildingType.mine: '⛏️',
  };

  String _effect(BuildingType type, Kingdom k) {
    switch (type) {
      case BuildingType.barracks:
        return '+${k.barracksBonus} к силе карт стихии';
      case BuildingType.wall:
        return '+${k.wallHpBonus} ХП замка';
      case BuildingType.mine:
        return '+${k.mineCrystalsPerWin} 💎 за победу';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveStateProvider);
    final controller = ref.read(saveStateProvider.notifier);
    final k = save.kingdom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Королевство'),
        actions: [
          CrystalChip(amount: save.crystals),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GameColors.backgroundStops,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final type in BuildingType.values)
              _BuildingCard(
                type: type,
                title: _titles[type]!,
                icon: _icons[type]!,
                level: k.levelOf(type),
                effect: _effect(type, k),
                crystals: save.crystals,
                onUpgrade: () => controller.tryUpgrade(type),
              ),
            if (k.barracksLevel >= 3) _CraftSection(save: save, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  final BuildingType type;
  final String title;
  final String icon;
  final int level;
  final String effect;
  final int crystals;
  final VoidCallback onUpgrade;

  const _BuildingCard({
    required this.type,
    required this.title,
    required this.icon,
    required this.level,
    required this.effect,
    required this.crystals,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final cost = KingdomEconomy.upgradeCost(type, level);
    final maxed = level >= 3;
    final canAfford = crystals >= cost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    _LevelPips(level: level),
                    const SizedBox(height: 4),
                    Text(effect,
                        style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              maxed
                  ? const Chip(label: Text('МАКС'))
                  : FilledButton(
                      onPressed: canAfford ? onUpgrade : null,
                      child: Text('Улучшить\n($cost💎)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelPips extends StatelessWidget {
  final int level;
  const _LevelPips({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Text(
            i < level ? '●' : '○',
            style: TextStyle(
              fontSize: 14,
              color: i < level ? const Color(0xFFF57C00) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _CraftSection extends StatelessWidget {
  final dynamic save;
  final dynamic controller;

  const _CraftSection({required this.save, required this.controller});

  @override
  Widget build(BuildContext context) {
    const craftId = 'trump_lava_cat';
    final alreadyCrafted = save.ownedCardIds.contains(craftId);

    if (alreadyCrafted) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Козырь кузницы создан 🏆',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🔮', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Особый козырь доступен в кузнице!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            FilledButton.tonal(
              onPressed: save.crystals >= 40
                  ? () {
                      controller.addCrystals(-40);
                      controller.grantCard(craftId);
                    }
                  : null,
              child: const Text('Создать козырь (40💎)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run kingdom tests**

```bash
cd /Users/greenolls/cursor/card_game && flutter test test/ui/kingdom_screen_test.dart
```
Expected: All 4 tests pass.

---

## Task 6: Redesign reward_screen.dart with trump name lookup

**Files:**
- Modify: `lib/ui/reward_screen.dart`

**Interfaces:**
- Consumes: `cardsProvider` from `lib/state/providers.dart`
- Must show trump display name (from cardsProvider), not raw id

- [ ] **Step 1: Rewrite reward_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets.dart';

class RewardScreen extends ConsumerWidget {
  final bool won;
  final int crystalsEarned;
  final String? trumpGranted;

  const RewardScreen({
    super.key,
    required this.won,
    required this.crystalsEarned,
    this.trumpGranted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);

    // Look up the trump display name if one was granted.
    String? trumpName;
    if (trumpGranted != null) {
      cardsAsync.whenData((cards) {
        // resolved synchronously if already loaded
      });
      final cards = cardsAsync.valueOrNull;
      if (cards != null) {
        trumpName = cards
            .where((c) => c.id == trumpGranted)
            .map((c) => c.name)
            .firstOrNull ?? trumpGranted;
      } else {
        trumpName = trumpGranted;
      }
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: GameColors.backgroundStops,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        won ? '🎉' : '💥',
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        won ? 'Победа!' : 'Поражение',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: won
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        won ? '🏰 Замок врага пал!' : '💀 Твой замок разрушен',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (won) CrystalChip(amount: crystalsEarned),
                      if (trumpName != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9C4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Text(
                            '🏆 Новый козырь: $trumpName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: () => Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                        child: const Text('В королевство'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Task 7: Redesign duel_screen.dart with full round-result reveal

**Files:**
- Modify: `lib/ui/duel_screen.dart`

**Interfaces:**
- Consumes: `RoundResult.playerCard`, `RoundResult.opponentCard` (from Task 1)
- Consumes: `GameCardView`, `CardBack`, `HpBar` from widgets.dart
- Must contain: «Замок» text

- [ ] **Step 1: Rewrite duel_screen.dart**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/duel_engine.dart';
import '../engine/duel_session.dart';
import '../engine/game_card.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'reward_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class DuelScreen extends ConsumerStatefulWidget {
  final MapNode node;
  const DuelScreen({super.key, required this.node});

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  DuelSession? _session;
  RoundResult? _lastResult;
  bool _resolved = false;
  bool _showReveal = false;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsProvider);
    final save = ref.watch(saveStateProvider);

    return cardsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Ошибка: $e'))),
      data: (allCards) {
        final session = _session ??= buildSession(
          save: save,
          allCards: allCards,
          node: widget.node,
          random: Random(widget.node.index + 1),
        );
        return _buildTable(session);
      },
    );
  }

  Widget _buildTable(DuelSession session) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.node.title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: GameColors.tabletopStops,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // ── TOP: opponent ─────────────────────────────────────────
                _OpponentZone(session: session),
                const SizedBox(height: 8),
                // ── CENTER: battle result ─────────────────────────────────
                Expanded(child: _BattleZone(result: _lastResult, showReveal: _showReveal)),
                const SizedBox(height: 8),
                // ── BOTTOM: player ────────────────────────────────────────
                _PlayerZone(
                  session: session,
                  resolved: _resolved,
                  onCardTap: (card) => _play(card, session),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _play(GameCard card, DuelSession session) {
    final result = session.playPlayerCard(card);
    setState(() {
      _lastResult = result;
      _showReveal = false;
    });
    // Trigger reveal animation on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showReveal = true);
    });

    final outcome = session.outcome;
    if (outcome != DuelOutcome.ongoing && !_resolved) {
      _resolved = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _finish(outcome == DuelOutcome.playerWon);
      });
    } else {
      setState(() {}); // refresh hand
    }
  }

  void _finish(bool won) {
    final controller = ref.read(saveStateProvider.notifier);
    final save = ref.read(saveStateProvider);
    final reward =
        computeDuelReward(node: widget.node, save: save, won: won, random: Random());
    if (won) {
      if (reward.crystalsEarned > 0) controller.addCrystals(reward.crystalsEarned);
      if (reward.unlockNext) controller.unlockNextNode();
      if (reward.trumpGranted != null) controller.grantCard(reward.trumpGranted!);
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => RewardScreen(
        won: won,
        crystalsEarned: reward.crystalsEarned,
        trumpGranted: reward.trumpGranted,
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OpponentZone extends StatelessWidget {
  final DuelSession session;
  const _OpponentZone({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HpBar(
          current: session.opponentCastleHp,
          max: session.opponentConfig.startingCastleHp,
          label: 'Замок врага',
          color: const Color(0xFFE53935),
        ),
        const SizedBox(height: 6),
        // Opponent hand as face-down cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final _ in session.opponentHand)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: CardBack(width: 52),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BattleZone extends StatelessWidget {
  final RoundResult? result;
  final bool showReveal;

  const _BattleZone({required this.result, required this.showReveal});

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const Center(
        child: Text(
          'Выбери карту, чтобы атаковать',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final r = result!;
    final playerWon = r.winner == RoundWinner.player;
    final isTie = r.winner == RoundWinner.tie;

    // Element hint
    final pEl = r.playerCard.element;
    final oEl = r.opponentCard.element;
    final pEmoji = GameColors.elementEmoji(pEl);
    final oEmoji = GameColors.elementEmoji(oEl);
    String elementHint = '';
    if (!isTie) {
      final winEl = playerWon ? pEl : oEl;
      final loseEl = playerWon ? oEl : pEl;
      final wEmoji = GameColors.elementEmoji(winEl);
      final lEmoji = GameColors.elementEmoji(loseEl);
      elementHint = '$wEmoji бьёт $lEmoji +${r.damage}';
    } else {
      elementHint = '$pEmoji vs $oEmoji — Ничья!';
    }

    // Result badge text
    String badgeText;
    if (isTie) {
      badgeText = 'Ничья!';
    } else if (playerWon) {
      badgeText = 'Победа!\n−${r.damage} ⚔️';
    } else {
      badgeText = 'Поражение\n−${r.damage} ⚔️';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Player card
            AnimatedOpacity(
              opacity: showReveal ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: GameCardView(
                card: r.playerCard,
                width: 80,
                highlighted: playerWon && !isTie,
                dimmed: !playerWon && !isTie,
              ),
            ),
            // Center badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedScale(
                scale: showReveal ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isTie
                        ? Colors.white70
                        : (playerWon
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isTie ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            // Opponent card (reveal animation)
            AnimatedScale(
              scale: showReveal ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              child: GameCardView(
                card: r.opponentCard,
                width: 80,
                highlighted: !playerWon && !isTie,
                dimmed: playerWon && !isTie,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: showReveal ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Text(
            elementHint,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlayerZone extends StatelessWidget {
  final DuelSession session;
  final bool resolved;
  final void Function(GameCard) onCardTap;

  const _PlayerZone({
    required this.session,
    required this.resolved,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HpBar(
          current: session.playerCastleHp,
          max: session.playerConfig.startingCastleHp,
          label: 'Твой замок',
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final card in session.playerHand)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GameCardView(
                    card: card,
                    width: 80,
                    onTap: resolved ? null : () => onCardTap(card),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run duel screen test**

```bash
cd /Users/greenolls/cursor/card_game && flutter test test/ui/duel_screen_test.dart
```
Expected: fails because test looks for `find.byType(Card)` — update in next task.

---

## Task 8: Update UI tests

**Files:**
- Modify: `test/ui/duel_screen_test.dart`

**Interfaces:**
- Consumes: `GameCardView` from `lib/ui/widgets.dart`

- [ ] **Step 1: Update duel screen test**

Replace `find.byType(Card)` with `find.byType(GameCardView)`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/duel_screen.dart';
import 'package:card_game/ui/duel_setup.dart';
import 'package:card_game/ui/widgets.dart';

void main() {
  testWidgets('duel screen renders castle hp and a playable hand', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: DuelScreen(node: kSliceNodes.first)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Замок'), findsWidgets);
    // Hand cards are rendered as GameCardView widgets; at least one exists.
    expect(find.byType(GameCardView), findsWidgets);
  });
}
```

- [ ] **Step 2: Run all UI tests**

```bash
cd /Users/greenolls/cursor/card_game && flutter test test/ui/
```
Expected: All tests pass.

- [ ] **Step 3: Run full suite**

```bash
cd /Users/greenolls/cursor/card_game && flutter test
```
Expected: All tests pass.

- [ ] **Step 4: Run analyze**

```bash
cd /Users/greenolls/cursor/card_game && flutter analyze
```
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
cd /Users/greenolls/cursor/card_game && git add -A && git commit -m "$(cat <<'EOF'
feat(ui): warm cartoon redesign + duel round-result reveal

Reworks all four screens with a parchment/amber palette and cartoon
feel. Duel screen now shows both cards played, winner highlight, damage
badge, element hint, and animated opponent-card flip. Updates duel
screen test to assert GameCardView instead of generic Card widget.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Write report

**Files:**
- Create: `.superpowers/sdd/redesign-report.md`

Summarise: engine change, theme/widget APIs, per-screen changes, test/analyze results, overflow mitigations.

---

## Self-Review Checklist

- [x] Engine: `RoundResult.playerCard/opponentCard` added + populated — Task 1
- [x] `flutter analyze` clean — Task 8 step 4
- [x] `flutter test` all green — Task 8 step 3
- [x] «Карта мира» preserved — Task 4
- [x] «Тренировка» + «БОСС» preserved — Task 4
- [x] «Казарма»/«Стена»/«Шахта» + «Создать козырь» — Task 5
- [x] «Замок» in duel — Task 7 (label strings «Замок врага» and «Твой замок»)
- [x] Duel test updated to `GameCardView` — Task 8
- [x] Reward screen shows trump NAME not id — Task 6
- [x] No external fonts/images — design uses colors, gradients, emoji only
- [x] No overflow: FittedBox in card name, SingleChildScrollView for hand rows
- [x] `lib/engine/` stays Flutter-free — only `duel_engine.dart` touched, no flutter import
- [x] Opponent card hidden in face-down `CardBack` widgets until played — `_OpponentZone`
- [x] Reveal animation — `AnimatedScale` + `AnimatedOpacity` in `_BattleZone`
