import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/app.dart';

void main() {
  testWidgets('app boots to the world map', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: CardGameApp()));
    // The splash precaches images behind an (infinitely animating) spinner, so
    // pumpAndSettle would never settle. Pump in real-async slices until the
    // world map appears.
    for (var i = 0; i < 40 && find.text('Карта мира').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    expect(find.text('Карта мира'), findsOneWidget);
  });
}
