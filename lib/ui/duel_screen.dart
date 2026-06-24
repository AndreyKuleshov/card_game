import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/ability.dart';
import '../engine/duel_engine.dart';
import '../engine/duel_session.dart';
import '../engine/element.dart';
import '../engine/game_card.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'game_assets.dart';
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

  // End-of-battle overlay state.
  bool _finished = false;
  bool _won = false;
  DuelReward? _reward;
  bool _rewardApplied = false;

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
          random: Random(), // fresh shuffle → a different deal every battle
        );
        return _buildTable(session, allCards);
      },
    );
  }

  Widget _buildTable(DuelSession session, List<GameCard> allCards) {
    GameCard? trumpCard;
    final trumpId = _reward?.trumpGranted;
    if (trumpId != null) {
      final m = allCards.where((c) => c.id == trumpId);
      if (m.isNotEmpty) trumpCard = m.first;
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.node.title)),
      body: Container(
        // Solid backdrop behind the scene (fills any transparent/letterboxed area).
        color: const Color(0xFF14110E),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Duel scene: table with both duelists baked in. The table surface
            // is the play area; UI overlays on top of it.
            Image.asset(
              GameAssets.duelLayout,
              fit: BoxFit.cover,
              // Nudge the scene slightly right (shows a bit more of the left crop).
              alignment: const Alignment(-0.045, 0),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            // Overlays positioned by fraction of height so they land on the
            // baked scene: HP at the edges, the villain's cards on the upper
            // table, the clash at the table centre, the player's hand on the
            // lower table (in front of the hero).
            SafeArea(
              // expand so the fractional Aligns and edge-pinned HP bars resolve
              // against the full screen (not a collapsed stack).
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Opponent HP — pinned to the very top.
                  Positioned(
                    top: 4,
                    left: 12,
                    right: 12,
                    child: HpBar(
                      current: session.opponentCastleHp,
                      max: session.opponentConfig.startingCastleHp,
                      label: 'Замок врага',
                      color: const Color(0xFFE53935),
                    ),
                  ),
                  // Opponent face-down hand — on the table in front of the villain.
                  Align(
                    alignment: const Alignment(0, -0.45),
                    child: _FaceDownHand(count: session.opponentHand.length),
                  ),
                  // Clash / play area — shows the opponent's pending card to
                  // answer (idle) or the clash result (after responding).
                  Align(
                    alignment: const Alignment(0, -0.19),
                    child: _BattleZone(
                      result: _lastResult,
                      pendingOpponentCard: session.pendingOpponentCard,
                      showReveal: _showReveal,
                      playerCardSlide: _playerCardSlide,
                      opponentCardSlide: _opponentCardSlide,
                      clashProgress: _clashProgress,
                    ),
                  ),
                  // Player trumps — once-per-battle, just above the hand.
                  if (session.availableTrumps.isNotEmpty)
                    Align(
                      alignment: const Alignment(0, 0.5),
                      child: _TrumpRow(
                        trumps: session.availableTrumps,
                        resolved: _resolved || _animating,
                        onTap: (card) => _respond(card, session),
                      ),
                    ),
                  // Player hand — low, in front of the hero (below his head).
                  Align(
                    alignment: const Alignment(0, 0.82),
                    child: _PlayerHand(
                      hand: session.playerHand,
                      resolved: _resolved || _animating,
                      onCardTap: (card) => _respond(card, session),
                    ),
                  ),
                  // Player HP — pinned to the very bottom.
                  Positioned(
                    bottom: 4,
                    left: 12,
                    right: 12,
                    child: HpBar(
                      current: session.playerCastleHp,
                      max: session.playerConfig.startingCastleHp,
                      label: 'Твой замок',
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ),
            // End-of-battle overlay (no navigation — drawn on top of the duel).
            if (_finished)
              _EndOverlay(
                won: _won,
                crystals: _reward?.crystalsEarned ?? 0,
                trumpCard: trumpCard,
                onClaim: _claimRewards,
                onExit: _exitToMap,
              ),
          ],
        ),
      ),
    );
  }

  void _respond(GameCard card, DuelSession session) {
    if (_animating || _resolved) return;

    final result = session.respond(card);
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
          // Let the player read the result, then advance to the opponent's
          // next card (clearing the result reveals the new pending card).
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _lastResult = null;
                _animating = false;
              });
            }
          });
        }
      });
    });
  }

  // Battle ended: compute the reward and show the end overlay (no navigation).
  // Rewards are credited when the chest is opened (see [_claimRewards]).
  void _finish(bool won) {
    final save = ref.read(saveStateProvider);
    final reward = computeDuelReward(
      node: widget.node,
      save: save,
      won: won,
      random: Random(),
    );
    setState(() {
      _finished = true;
      _won = won;
      _reward = reward;
    });
  }

  // Credit crystals / trump / unlock when the player opens the chest (win only).
  void _claimRewards() {
    if (_rewardApplied || !_won || _reward == null) return;
    _rewardApplied = true;
    final controller = ref.read(saveStateProvider.notifier);
    final r = _reward!;
    if (r.crystalsEarned > 0) controller.addCrystals(r.crystalsEarned);
    if (r.unlockNext) controller.unlockNextNode();
    if (r.trumpGranted != null) controller.grantCard(r.trumpGranted!);
  }

  void _exitToMap() =>
      Navigator.of(context).popUntil((route) => route.isFirst);
}

// ─────────────────────────────────────────────────────────────────────────────
// Opponent face-down hand — laid on the upper table in front of the villain
// ─────────────────────────────────────────────────────────────────────────────

class _FaceDownHand extends StatelessWidget {
  final int count;

  const _FaceDownHand({required this.count});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: CardBack(width: 46),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Battle zone — shows last round result or a hint
// ─────────────────────────────────────────────────────────────────────────────

class _BattleZone extends StatelessWidget {
  final RoundResult? result;
  final GameCard? pendingOpponentCard;
  final bool showReveal;
  final Animation<double> playerCardSlide;
  final Animation<double> opponentCardSlide;
  final Animation<double> clashProgress;

  const _BattleZone({
    required this.result,
    required this.pendingOpponentCard,
    required this.showReveal,
    required this.playerCardSlide,
    required this.opponentCardSlide,
    required this.clashProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      // Idle: the opponent has played a card — show it face-up for the player
      // to answer. Returned unwrapped (no Center) so the parent Align places it.
      final pending = pendingOpponentCard;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pending != null)
            GameCardView(card: pending, width: 84)
          else
            const SizedBox.shrink(),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(110),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Ответь картой',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
      mainAxisSize: MainAxisSize.min,
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
// Player hand — tappable cards laid on the lower table in front of the hero
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerHand extends StatelessWidget {
  final List<GameCard> hand;
  final bool resolved;
  final void Function(GameCard) onCardTap;

  const _PlayerHand({
    required this.hand,
    required this.resolved,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final card in hand)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GameCardView(
                card: card,
                width: 76,
                onTap: resolved ? null : () => onCardTap(card),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrumpRow — owned trumps, each playable once per battle (as the round answer)
// ─────────────────────────────────────────────────────────────────────────────

class _TrumpRow extends StatelessWidget {
  final List<GameCard> trumps;
  final bool resolved;
  final void Function(GameCard) onTap;

  const _TrumpRow({
    required this.trumps,
    required this.resolved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final card in trumps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GameCardView(
                card: card,
                width: 60,
                highlighted: true,
                onTap: resolved ? null : () => onTap(card),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EndOverlay — drawn on top of the duel when a battle ends (no navigation).
// Win: a chest the player taps to open; crystals + trump spill out. Loss: a
// defeat card. Both end with a "В королевство" button.
// ─────────────────────────────────────────────────────────────────────────────

class _EndOverlay extends StatefulWidget {
  final bool won;
  final int crystals;
  final GameCard? trumpCard;
  final VoidCallback onClaim; // credit rewards (win, when the chest opens)
  final VoidCallback onExit;

  const _EndOverlay({
    required this.won,
    required this.crystals,
    required this.trumpCard,
    required this.onClaim,
    required this.onExit,
  });

  @override
  State<_EndOverlay> createState() => _EndOverlayState();
}

class _EndOverlayState extends State<_EndOverlay> {
  bool _open = false;

  void _openChest() {
    setState(() => _open = true);
    widget.onClaim();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(180),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: widget.won ? _win(context) : _loss(context),
          ),
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String text, Color color) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(color: color),
      );

  Widget _exitButton() => FilledButton(
        onPressed: widget.onExit,
        child: const Text('В королевство'),
      );

  Widget _loss(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💥', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          _title(context, 'Поражение', const Color(0xFFC62828)),
          const SizedBox(height: 8),
          const Text('💀 Твой замок разрушен',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 28),
          _exitButton(),
        ],
      );

  Widget _win(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title(context, 'Победа!', const Color(0xFF66BB6A)),
        const SizedBox(height: 18),
        if (!_open) ...[
          GestureDetector(
            onTap: _openChest,
            child: Image.asset(
              GameAssets.chestClosed,
              width: 170,
              errorBuilder: (_, _, _) =>
                  const Text('🧰', style: TextStyle(fontSize: 110)),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Нажми, чтобы открыть',
              style: TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ] else ...[
          Image.asset(
            GameAssets.chestOpen,
            width: 180,
            errorBuilder: (_, _, _) =>
                const Text('🧰', style: TextStyle(fontSize: 120)),
          ),
          const SizedBox(height: 14),
          // Rewards spill out with a quick scale-in.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, t, child) =>
                Transform.scale(scale: t.clamp(0.0, 1.0), child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                  ),
                  child: Text(
                    '+${widget.crystals} 💎',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
                if (widget.trumpCard != null) ...[
                  const SizedBox(height: 14),
                  const Text('🏆 Новый козырь!',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  GameCardView(card: widget.trumpCard!, width: 96),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _exitButton(),
        ],
      ],
    );
  }
}
