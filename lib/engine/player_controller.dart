import 'duel_engine.dart';
import 'game_card.dart';

abstract class PlayerController {
  /// Choose a card to play this round from [hand].
  GameCard chooseCard({
    required List<GameCard> hand,
    required DuelConfig config,
    GameCard? opponentLastCard,
  });
}

/// Human moves arrive from the UI, not from this method. The class exists so
/// the duel flow is symmetric and a RemoteController can slot in later.
class HumanController extends PlayerController {
  @override
  GameCard chooseCard({
    required List<GameCard> hand,
    required DuelConfig config,
    GameCard? opponentLastCard,
  }) {
    throw UnimplementedError('Human moves are supplied by the UI layer.');
  }
}
