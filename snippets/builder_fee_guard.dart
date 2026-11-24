// Excerpt from AXIS (lib/state/admin_config_provider.dart). Shown for illustration only.
// The full source code is available at https://store.mikodes.com/p/axis/
//
// How the operator builder fee reaches an order. It is attached only when it is switched on,
// the address is well formed and the fee is within the exchange limit. Anything else fails
// closed: trade with no builder fee rather than have every order rejected.

// (members of the operator-config provider)
  /// Hyperliquid's builder-fee limit on perps: 0.1% = 10 bp = 100 tenths.
  /// Source: Hyperliquid docs, "Builder fees charged can be at most 0.1% on
  /// perps and 1% on spot."
  static const int maxHyperliquidBuilderFeeTenthsBps = 100;

  /// The operator builder to attach to a crypto perps order, or null when the
  /// fee is switched off, unconfigured or out of range.
  ({String address, int feeTenthsBps})? get hyperliquidBuilder {
    final String address = _config.builderAddress.trim();
    if (!_config.builderFeeEnabled ||
        address.isEmpty ||
        _config.builderFeeTenthsBps <= 0) {
      return null;
    }
    // A malformed address, or a fee above Hyperliquid's perps limit, would make
    // every user's one-time builder approval fail — and with it every perps
    // order. Fail closed: trade with no builder fee rather than not at all.
    if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address) ||
        _config.builderFeeTenthsBps > maxHyperliquidBuilderFeeTenthsBps) {
      return null;
    }
    return (address: address, feeTenthsBps: _config.builderFeeTenthsBps);
  }

  /// Same builder address, but carrying the stock-dex fee when one is set.
  /// Null in exactly the cases [hyperliquidBuilder] is null.
  ({String address, int feeTenthsBps})? get hyperliquidStockBuilder {
    final perps = hyperliquidBuilder;
    if (perps == null) return null;
    final int stockFee = _config.builderFeeStockTenthsBps;
    final int fee = stockFee > 0 ? stockFee : perps.feeTenthsBps;
    if (fee > maxHyperliquidBuilderFeeTenthsBps) return null;
    return (address: perps.address, feeTenthsBps: fee);
  }
