/// Trump-card abilities used in the vertical slice.
enum Ability {
  /// Ignore the opponent's element bonus this round.
  elementalShift,

  /// Deal x1.5 damage (floored) on a won round.
  doubleStrike,

  /// Take no castle damage on a lost round.
  shield,
}

/// Card rarity tiers.
enum Rarity { common, rare, trump }
