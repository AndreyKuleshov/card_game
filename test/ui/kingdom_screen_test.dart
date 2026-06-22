import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/kingdom_screen.dart';
import 'package:card_game/state/providers.dart';
import 'package:card_game/engine/kingdom.dart';

void main() {
  testWidgets('kingdom screen lists three buildings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: KingdomScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Казарма'), findsOneWidget);
    expect(find.text('Стена'), findsOneWidget);
    expect(find.text('Шахта'), findsOneWidget);
  });

  testWidgets('craft button is absent below barracks level 3', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: KingdomScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Создать козырь'), findsNothing);
  });

  testWidgets('craft button appears only at barracks level 3', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    // Force barracks to level 3 with plenty of crystals.
    final ctrl = container.read(saveStateProvider.notifier);
    ctrl.addCrystals(100);
    ctrl.tryUpgrade(BuildingType.barracks); // 1->2
    ctrl.tryUpgrade(BuildingType.barracks); // 2->3
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: KingdomScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Создать козырь'), findsOneWidget);
  });

  testWidgets('tapping craft button grants trump_lava_cat', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    final ctrl = container.read(saveStateProvider.notifier);
    // Need enough crystals for two barracks upgrades (10+20) and the craft (40).
    ctrl.addCrystals(200);
    ctrl.tryUpgrade(BuildingType.barracks); // 1->2
    ctrl.tryUpgrade(BuildingType.barracks); // 2->3
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: KingdomScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать козырь (40💎)'));
    await tester.pumpAndSettle();
    expect(container.read(saveStateProvider).ownedCardIds, contains('trump_lava_cat'));
  });
}
