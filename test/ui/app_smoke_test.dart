import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/app.dart';

void main() {
  testWidgets('app boots to the world map', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: CardGameApp()));
    await tester.pumpAndSettle();
    expect(find.text('Карта мира'), findsOneWidget);
  });
}
