import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/duel_screen.dart';
import 'package:card_game/ui/duel_setup.dart';
import 'package:card_game/ui/widgets.dart';

void main() {
  testWidgets('duel screen renders castle hp and a playable hand', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: DuelScreen(node: kSliceNodes.first)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Замок'), findsWidgets);
    // Hand cards are rendered as GameCardView widgets; at least one exists.
    expect(find.byType(GameCardView), findsWidgets);
  });
}
