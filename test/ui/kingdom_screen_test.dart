import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/kingdom_screen.dart';
import 'package:card_game/state/providers.dart';
import 'package:card_game/engine/kingdom.dart';

void main() {
  testWidgets('kingdom screen lists five buildings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: KingdomScreen()),
    ));
    await tester.pumpAndSettle();
    // Titles appear on the scene AND in the panel, so we expect at least one.
    expect(find.text('Зажигалка'), findsWidgets);
    expect(find.text('Полторашка'), findsWidgets);
    expect(find.text('Травка'), findsWidgets);
    expect(find.text('Стена'), findsWidgets);
    expect(find.text('Шахта'), findsWidgets);
  });

  testWidgets('craft button is absent below fireForge level 3', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: KingdomScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Создать козырь'), findsNothing);
  });

  testWidgets('craft button appears only at fireForge level 3', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    // Force fireForge to level 3 with plenty of crystals.
    final ctrl = container.read(saveStateProvider.notifier);
    ctrl.addCrystals(100);
    ctrl.tryUpgrade(BuildingType.fireForge); // 0->1
    ctrl.tryUpgrade(BuildingType.fireForge); // 1->2
    ctrl.tryUpgrade(BuildingType.fireForge); // 2->3
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
    // Need enough crystals to build fireForge 0->3 (5+10+25) and craft (40).
    ctrl.addCrystals(200);
    ctrl.tryUpgrade(BuildingType.fireForge); // 0->1
    ctrl.tryUpgrade(BuildingType.fireForge); // 1->2
    ctrl.tryUpgrade(BuildingType.fireForge); // 2->3
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
