import 'duel_engine.dart';
import 'game_card.dart';
import 'player_controller.dart';

class AiController extends PlayerController {
  @override
  GameCard chooseCard({
    required List<GameCard> hand,
    required DuelConfig config,
    GameCard? opponentLastCard,
  }) {
    final sorted = List<GameCard>.of(hand)
      ..sort((a, b) {
        final byPower = b.power.compareTo(a.power);
        return byPower != 0 ? byPower : a.id.compareTo(b.id);
      });
    return sorted.first;
  }
}
