import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/providers.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(saveStateProvider.notifier).hydrate();
  runApp(UncontrolledProviderScope(container: container, child: const CardGameApp()));
}
