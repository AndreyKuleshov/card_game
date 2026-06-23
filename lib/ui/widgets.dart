import 'package:flutter/material.dart';
import '../engine/ability.dart';
import '../engine/game_card.dart';
import 'theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GameCardView
// ─────────────────────────────────────────────────────────────────────────────

/// A tappable card tile with element gradient, name, power badge and rarity
/// star. [highlighted] adds a golden glow and a slight scale; [dimmed] lowers
/// opacity. The card name is rendered inside a [FittedBox] so it never
/// overflows regardless of text length.
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
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Element emoji
                Text(
                  GameColors.elementEmoji(card.element),
                  style: TextStyle(fontSize: width * 0.28),
                  textAlign: TextAlign.center,
                ),
                // Card name — FittedBox prevents overflow
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
              width: 26,
              height: 26,
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
                    fontSize: 12,
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

    // Scale highlighted cards slightly for emphasis
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

/// Face-down card showing a decorative gradient back with a shield crest.
/// Used to represent opponent hand cards without revealing their contents.
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
          style: TextStyle(fontSize: width * 0.36),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HpBar
// ─────────────────────────────────────────────────────────────────────────────

/// Animated castle HP bar. The fill is clamped to [0, 1] so it is always safe
/// to pass any value including negative HP.
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
                  color: Colors.white,
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
            color: Colors.black26,
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

/// A compact pill widget showing a crystal count: 💎 N.
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
