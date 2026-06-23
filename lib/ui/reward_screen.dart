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
    // Look up the trump display name from the card catalogue when available.
    String? trumpName;
    if (trumpGranted != null) {
      final cards = ref.watch(cardsProvider).value;
      if (cards != null) {
        final match = cards.where((c) => c.id == trumpGranted);
        trumpName = match.isNotEmpty ? match.first.name : trumpGranted;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
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
                            horizontal: 12,
                            vertical: 8,
                          ),
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
