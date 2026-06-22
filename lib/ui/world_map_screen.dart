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
              _NodeCard(
                node: node,
                unlocked: node.index <= save.unlockedNodeIndex,
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    ? const Text(
                        'играть ▶',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF57C00),
                        ),
                      )
                    : const Text(
                        '🔒',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
