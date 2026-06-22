import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/collection_screen.dart';

void main() {
  testWidgets('collection screen shows title and trumps section', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: CollectionScreen()),
    ));
    await tester.pumpAndSettle();

    // AppBar title
    expect(find.text('Коллекция'), findsOneWidget);

    // Trumps section header
    expect(find.text('🏆 Козыри'), findsOneWidget);

    // Starter trump 'trump_starter_drake' is owned — at least one trump card
    // appears (the «Пока нет козырей» hint must NOT be visible).
    expect(
      find.text(
        'Пока нет козырей — побеждай, крафти и бей боссов!',
      ),
      findsNothing,
    );
  });
}
