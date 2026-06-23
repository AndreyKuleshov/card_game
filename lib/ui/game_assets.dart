import '../engine/kingdom.dart';

/// Centralised asset paths for the generated artwork. Keeping them in one place
/// means a renamed/missing file is fixed once. All widgets that load these wrap
/// them with an `errorBuilder` fallback to procedural art, so a missing file
/// degrades gracefully instead of crashing.
class GameAssets {
  GameAssets._();

  /// Per-card artwork, keyed by [GameCard.id] (e.g. `fire_deer`).
  static String card(String id) => 'assets/cards/$id.png';

  /// Decorative face-down card back.
  static const String cardBack = 'assets/cards/card_back.png';

  /// Central kingdom castle.
  static const String castle = 'assets/kingdom/castle.png';

  /// Building artwork — the file name matches the [BuildingType] enum name
  /// (`fireForge.png`, `waterWell.png`, `natureGrove.png`, `wall.png`,
  /// `mine.png`).
  static String building(BuildingType type) => 'assets/kingdom/${type.name}.png';

  /// Seated duelist portrait — villain for the opponent, hero for the player.
  static String duelist({required bool isOpponent}) => isOpponent
      ? 'assets/duel/villain_opponent.png'
      : 'assets/duel/hero_player.png';

  /// Wooden-plank table surface used as the duel background.
  static const String duelTable = 'assets/backgrounds/duel_table.png';

  // ── UI icons (replace inline emoji) ──────────────────────────────────────
  static const String iconCrystal = 'assets/icons/icon_crystal.png';
  static const String iconCastle = 'assets/icons/icon_castle.png';

  /// All card ids (keep in sync with assets/cards.json).
  static const List<String> _cardIds = [
    'fire_deer', 'fire_rooster', 'fire_pie', 'fire_phoenix_pearl',
    'nature_zucchini', 'nature_forester', 'nature_mushroom', 'nature_hedgehog',
    'water_jellyfish', 'water_puddle', 'water_beaver', 'water_dumpling',
    'trump_pumpkin_king', 'trump_lava_cat', 'trump_frost_granny',
    'trump_starter_drake',
  ];

  /// Every artwork the app shows during play — precached at startup behind a
  /// spinner so screens never pop in with missing images.
  static List<String> get preload => [
        for (final id in _cardIds) card(id),
        cardBack,
        castle,
        for (final t in BuildingType.values) building(t),
        duelist(isOpponent: true),
        duelist(isOpponent: false),
        duelTable,
        iconCrystal,
        iconCastle,
      ];
}
