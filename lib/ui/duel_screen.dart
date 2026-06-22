import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/ability.dart';
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
    with TickerProviderStateMixin {
  DuelSession? _session;
  RoundResult? _lastResult;
  bool _resolved = false;
  bool _showReveal = false;
  bool _animating = false;

  // Animation controller for the card-play slide-in effect.
  late final AnimationController _cardAnimController;
  late final Animation<double> _playerCardSlide;
  late final Animation<double> _opponentCardSlide;

  // Animation controller for the clash effect (lunge / recoil / spark).
  late final AnimationController _clashController;
  late final Animation<double> _clashProgress;

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

    // Clash controller: 0 → 1 → 0 arc (lunge, impact, recoil)
    _clashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _clashProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _clashController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    _clashController.dispose();
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
                    clashProgress: _clashProgress,
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
    _clashController.reset();
    _cardAnimController.forward().then((_) {
      if (!mounted) return;
      // After slide-in, play the clash animation
      _clashController.forward().then((_) {
        if (!mounted) return;
        // After clash, trigger the reveal (badge + hint)
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
  final Animation<double> clashProgress;

  const _BattleZone({
    required this.result,
    required this.showReveal,
    required this.playerCardSlide,
    required this.opponentCardSlide,
    required this.clashProgress,
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
    // Break the bonus into parts so the Казарма bonus (+🏹) is visible
    // separately from the element advantage (+stihiya emoji): "6 +3🔥 +1🏹 = 10".
    String side(GameCard card, GameCard opp, int eff) {
      final elem = (opp.ability != Ability.elementalShift &&
              ElementRules.beats(card.element, opp.element))
          ? kElementBonus
          : 0;
      final other = eff - card.power - elem; // Казарма / прочие бонусы
      final b = StringBuffer('${card.power}');
      if (elem > 0) b.write(' +$elem${GameColors.elementEmoji(card.element)}');
      if (other > 0) b.write(' +$other⚒️');
      if (eff != card.power) b.write(' = $eff');
      return b.toString();
    }

    final power =
        'сила ${side(r.playerCard, r.opponentCard, r.playerEffectivePower)}'
        ' : ${side(r.opponentCard, r.playerCard, r.opponentEffectivePower)}';
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

    // Clash values derived from clashProgress (0→1 arc).
    // Winner lunges toward loser (translate toward center + scale up),
    // loser recoils away and dims. On tie, both bounce gently.
    // clashProgress: 0=idle, 0.5=peak impact, 1=settled.
    // We map it through a "lunge then return" curve: sin(π*t) for [0..1].

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Player card — slides up from below, then clashes
                AnimatedBuilder(
                  animation: Listenable.merge([playerCardSlide, clashProgress]),
                  builder: (context, child) {
                    final slide = playerCardSlide.value * 80;
                    final slideOpacity = (1.0 - playerCardSlide.value.abs()).clamp(0.0, 1.0);
                    // Clash: lunge right toward center, scale up
                    final lunge = isTie
                        ? _bounceValue(clashProgress.value) * 6
                        : (playerWon
                            ? _lungeValue(clashProgress.value) * 22
                            : -_recoilValue(clashProgress.value) * 10);
                    final scaleBoost = isTie
                        ? 1.0
                        : (playerWon
                            ? 1.0 + _lungeValue(clashProgress.value) * 0.14
                            : 1.0 - _recoilValue(clashProgress.value) * 0.08);
                    final clashOpacity = (!isTie && !playerWon)
                        ? (1.0 - _recoilValue(clashProgress.value) * 0.35)
                        : 1.0;
                    return Transform.translate(
                      offset: Offset(lunge, slide),
                      child: Transform.scale(
                        scale: scaleBoost,
                        child: Opacity(
                          opacity: (slideOpacity * clashOpacity).clamp(0.0, 1.0),
                          child: child,
                        ),
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
                // Center result badge — pops in after clash
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
                // Opponent card — slides down from above, then clashes
                AnimatedBuilder(
                  animation: Listenable.merge([opponentCardSlide, clashProgress]),
                  builder: (context, child) {
                    final slide = opponentCardSlide.value * 80;
                    final slideOpacity = (1.0 - opponentCardSlide.value.abs()).clamp(0.0, 1.0);
                    // Clash: lunge left toward center, scale up
                    final lunge = isTie
                        ? -_bounceValue(clashProgress.value) * 6
                        : (!playerWon
                            ? -_lungeValue(clashProgress.value) * 22
                            : _recoilValue(clashProgress.value) * 10);
                    final scaleBoost = isTie
                        ? 1.0
                        : (!playerWon
                            ? 1.0 + _lungeValue(clashProgress.value) * 0.14
                            : 1.0 - _recoilValue(clashProgress.value) * 0.08);
                    final clashOpacity = (!isTie && playerWon)
                        ? (1.0 - _recoilValue(clashProgress.value) * 0.35)
                        : 1.0;
                    return Transform.translate(
                      offset: Offset(lunge, slide),
                      child: Transform.scale(
                        scale: scaleBoost,
                        child: Opacity(
                          opacity: (slideOpacity * clashOpacity).clamp(0.0, 1.0),
                          child: child,
                        ),
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
            // Impact spark — briefly visible at peak clash (t≈0.5), then fades
            AnimatedBuilder(
              animation: clashProgress,
              builder: (context, _) {
                final t = clashProgress.value;
                // spark peaks around t=0.4..0.6
                final sparkOpacity = (t < 0.5
                    ? (t / 0.5).clamp(0.0, 1.0)
                    : ((1.0 - t) / 0.5).clamp(0.0, 1.0));
                final sparkScale = 0.5 + sparkOpacity * 0.8;
                if (sparkOpacity < 0.05) return const SizedBox.shrink();
                return Opacity(
                  opacity: sparkOpacity,
                  child: Transform.scale(
                    scale: sparkScale,
                    child: Text(
                      isTie ? '💫' : '⚔️',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              },
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

  // Lunge curve: rises fast to peak at t=0.5, then quickly returns.
  // sin(π*t) gives a smooth arc from 0→1→0 over [0..1].
  static double _lungeValue(double t) {
    // Approximate sin(π*t) without dart:math import:
    // Use a quadratic: 4*t*(1-t) peaks at 1.0 at t=0.5 (close to sin(π*t)).
    return 4.0 * t * (1.0 - t);
  }

  // Recoil: builds from 0 and stays elevated (winner pushes away loser).
  // Peaks around t=0.5 then eases back slightly.
  static double _recoilValue(double t) {
    return (t < 0.6) ? (t / 0.6).clamp(0.0, 1.0) : 1.0 - ((t - 0.6) / 0.4) * 0.3;
  }

  // Bounce: gentle symmetric bump (for tie).
  static double _bounceValue(double t) {
    return 4.0 * t * (1.0 - t) * 0.5;
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
