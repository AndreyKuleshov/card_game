import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/duel_engine.dart';
import '../engine/duel_session.dart';
import '../engine/element.dart';
import '../engine/game_card.dart';
import '../state/providers.dart';
import 'art.dart';
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

class _DuelScreenState extends ConsumerState<DuelScreen>
    with SingleTickerProviderStateMixin {
  DuelSession? _session;
  RoundResult? _lastResult;
  bool _resolved = false;
  bool _showReveal = false;
  bool _animating = false;

  // Animation controller for the card-play slide-in effect.
  late final AnimationController _cardAnimController;
  late final Animation<double> _playerCardSlide;
  late final Animation<double> _opponentCardSlide;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    // Player card slides up from bottom (1.0 → 0.0 offset fraction of card height)
    _playerCardSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutCubic),
    );
    // Opponent card slides down from top
    _opponentCardSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

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
                // ── TOP: opponent ─────────────────────────────────────
                _OpponentZone(session: session),
                const SizedBox(height: 8),
                // ── CENTER: battle result ─────────────────────────────
                Expanded(
                  child: _BattleZone(
                    result: _lastResult,
                    showReveal: _showReveal,
                    playerCardSlide: _playerCardSlide,
                    opponentCardSlide: _opponentCardSlide,
                  ),
                ),
                const SizedBox(height: 8),
                // ── BOTTOM: player ────────────────────────────────────
                _PlayerZone(
                  session: session,
                  resolved: _resolved || _animating,
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
    if (_animating || _resolved) return;

    final result = session.playPlayerCard(card);
    setState(() {
      _lastResult = result;
      _showReveal = false;
      _animating = true;
    });

    // Reset and start the slide-in animation
    _cardAnimController.reset();
    _cardAnimController.forward().then((_) {
      if (!mounted) return;
      // After slide-in, trigger the reveal (badge + hint)
      setState(() => _showReveal = true);

      final outcome = session.outcome;
      if (outcome != DuelOutcome.ongoing && !_resolved) {
        _resolved = true;
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _finish(outcome == DuelOutcome.playerWon);
        });
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _animating = false);
        });
      }
    });
  }

  void _finish(bool won) {
    final controller = ref.read(saveStateProvider.notifier);
    final save = ref.read(saveStateProvider);
    final reward = computeDuelReward(
      node: widget.node,
      save: save,
      won: won,
      random: Random(),
    );
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
// Opponent zone — HP bar + face-down hand
// ─────────────────────────────────────────────────────────────────────────────

class _OpponentZone extends StatelessWidget {
  final DuelSession session;

  const _OpponentZone({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const DuelistPainterView(isOpponent: true, size: 44),
            const SizedBox(width: 8),
            Expanded(
              child: HpBar(
                current: session.opponentCastleHp,
                max: session.opponentConfig.startingCastleHp,
                label: 'Замок врага',
                color: const Color(0xFFE53935),
              ),
            ),
          ],
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
// Battle zone — shows last round result or a hint
// ─────────────────────────────────────────────────────────────────────────────

class _BattleZone extends StatelessWidget {
  final RoundResult? result;
  final bool showReveal;
  final Animation<double> playerCardSlide;
  final Animation<double> opponentCardSlide;

  const _BattleZone({
    required this.result,
    required this.showReveal,
    required this.playerCardSlide,
    required this.opponentCardSlide,
  });

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

    // Hint line: always show the effective powers (these already fold in the
    // element bonus AND the Казарма bonus), and only call out "бьёт" when there
    // is a genuine element advantage — same-element matchups have none.
    final pEmoji = GameColors.elementEmoji(r.playerCard.element);
    final oEmoji = GameColors.elementEmoji(r.opponentCard.element);
    // Show base+bonus=effective so the jump from the card's printed power to its
    // battle power (element advantage + Казарма) is obvious.
    String side(int base, int eff) =>
        eff > base ? '$base+${eff - base}=$eff' : '$eff';
    final power = 'сила ${side(r.playerCard.power, r.playerEffectivePower)}'
        ' : ${side(r.opponentCard.power, r.opponentEffectivePower)}';
    final String elementHint;
    if (isTie) {
      elementHint = '$power — ничья';
    } else {
      final winnerBeats = playerWon
          ? ElementRules.beats(r.playerCard.element, r.opponentCard.element)
          : ElementRules.beats(r.opponentCard.element, r.playerCard.element);
      if (winnerBeats) {
        final winEmoji = playerWon ? pEmoji : oEmoji;
        final loseEmoji = playerWon ? oEmoji : pEmoji;
        elementHint = '$winEmoji бьёт $loseEmoji  •  $power';
      } else {
        elementHint = power;
      }
    }

    // Result badge label
    final String badgeText;
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
            // Player card — slides up from below and fades in
            AnimatedBuilder(
              animation: playerCardSlide,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, playerCardSlide.value * 80),
                  child: Opacity(
                    opacity: (1.0 - playerCardSlide.value.abs()).clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: GameCardView(
                card: r.playerCard,
                width: 80,
                highlighted: playerWon && !isTie,
                dimmed: !playerWon && !isTie,
              ),
            ),
            // Center result badge — pops in after slide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AnimatedScale(
                scale: showReveal ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: AnimatedOpacity(
                  opacity: showReveal ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
            ),
            // Opponent card — slides down from above
            AnimatedBuilder(
              animation: opponentCardSlide,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, opponentCardSlide.value * 80),
                  child: Opacity(
                    opacity: (1.0 - opponentCardSlide.value.abs()).clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
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
// Player zone — HP bar + tappable hand
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const DuelistPainterView(isOpponent: false, size: 44),
            const SizedBox(width: 8),
            Expanded(
              child: HpBar(
                current: session.playerCastleHp,
                max: session.playerConfig.startingCastleHp,
                label: 'Твой замок',
                color: const Color(0xFF1565C0),
              ),
            ),
          ],
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
