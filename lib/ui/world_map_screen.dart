import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'duel_screen.dart';
import 'kingdom_screen.dart';

class WorldMapScreen extends ConsumerWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта мира'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text('💎 ${save.crystals}')),
          ),
          IconButton(
            icon: const Icon(Icons.castle),
            tooltip: 'Королевство',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KingdomScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final node in kSliceNodes)
            Card(
              child: ListTile(
                leading: Icon(node.isBoss ? Icons.whatshot : Icons.flag),
                title: Text(node.title),
                trailing: node.index <= save.unlockedNodeIndex
                    ? const Icon(Icons.play_arrow)
                    : const Icon(Icons.lock),
                enabled: node.index <= save.unlockedNodeIndex,
                onTap: node.index <= save.unlockedNodeIndex
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DuelScreen(node: node)),
                        )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
