// Excerpt from AXIS (lib/core/hyperliquid/perps_order_math.dart). Shown for illustration only.
// The full source code is available at https://store.mikodes.com/p/axis/
//
// Pure order-ticket math. The isolated liquidation estimate uses the exchange formula with
// maintenance margin, so liquidation lands earlier than the naive entry / leverage figure,
// and an unknown input returns null instead of a made-up price.

/// every position depends on is unit-tested independently of the widget tree.
class PerpsOrderMath {

  /// Maintenance-margin fraction of notional for a market whose maximum
  /// leverage is [maxLeverage].
  ///
  /// Hyperliquid's maintenance leverage is twice a market's max leverage, so
  /// maintenance margin is half the initial margin required at max leverage:
  /// `l = 1 / (2 · maxLeverage)`. Returns 0 when [maxLeverage] is unknown,
  /// which makes the liquidation estimates below degrade to "no maintenance
  /// margin" rather than throwing — callers must treat a 0 here as a reason to
  /// show no figure at all.
  static double maintenanceMarginFraction(int maxLeverage) =>
      maxLeverage <= 0 ? 0 : 1 / (2 * maxLeverage);

  /// Estimated ISOLATED liquidation price, or null when it cannot be computed.
  ///
  /// Hyperliquid's documented formula is
  /// `liq = entry − side · marginAvailable / size / (1 − side · l)`, where for
  /// an isolated position `marginAvailable = isolatedMargin − maintenance`,
  /// `isolatedMargin = notional / leverage`, `maintenance = notional · l` and
  /// `l` is [maintenanceMarginFraction]. Notional and size cancel, leaving a
  /// pure function of the entry.
  ///
  /// The naive `entry ± entry / leverage` is not conservative. Maintenance
  /// margin is consumed BEFORE the margin is gone, so liquidation always
  /// arrives EARLIER than `entry / leverage` — never later. On BTC (max
  /// leverage 40) a 40x long entered at 100,000 liquidates at 98,734.18, a
  /// distance of 1.27%, where the naive figure would say 97,500 (2.50%).
  static double? isolatedLiqPrice({
    required double entry,
    required double leverage,
    required bool isLong,
    required int maxLeverage,
  }) {
    if (entry <= 0 || leverage <= 0 || maxLeverage <= 0) return null;
    final double l = maintenanceMarginFraction(maxLeverage);
    final double side = isLong ? 1.0 : -1.0;
    final double denom = 1 - side * l;
    if (denom <= 0) return null;
    final double liq = entry * (1 - side * (1 / leverage - l) / denom);
    // A long is only wiped out at a zero price once leverage reaches 1x; a
    // negative result is not a price.
    return liq <= 0 ? 0 : liq;
  }
}
