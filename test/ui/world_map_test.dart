import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/world_map_screen.dart';

void main() {
  testWidgets('world map shows nodes and locks future ones', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: WorldMapScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Карта мира'), findsOneWidget);
    expect(find.text('Тренировка'), findsOneWidget);
    expect(find.textContaining('БОСС'), findsOneWidget);
  });
}
