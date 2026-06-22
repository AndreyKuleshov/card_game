import 'package:flutter/material.dart';

class RewardScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(won ? 'Победа!' : 'Поражение')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(won ? '🎉 Замок врага пал!' : '💥 Твой замок разрушен',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (won) Text('Получено: 💎 $crystalsEarned'),
            if (trumpGranted != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('🏆 Новый козырь: $trumpGranted'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
              child: const Text('В королевство'),
            ),
          ],
        ),
      ),
    );
  }
}
