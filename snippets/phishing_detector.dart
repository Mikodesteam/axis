// Excerpt from AXIS (lib/core/phishing_detector.dart). Shown for illustration only. The full source code is available at https://store.mikodes.com/p/axis/
//
// Checks a dApp URL before the wallet opens it: invalid or non-http(s) links
// and known phishing domains are blocked, look-alike domains (one or two
// letters off a trusted site) and scam keywords raise a warning.
// The block list, trusted list and feed refresh logic are cut.

  static PhishingCheck analyzeUrl(String rawUrl) {
    final parsed = Uri.tryParse(rawUrl.trim());
    final mode = feedMode;
    final source = activeFeedSourceLabel;
    final blockedDomains = _activeBlockedDomains;
    final trustedDomains = _activeTrustedDomains;

    if (parsed == null || !parsed.hasScheme) {
      return PhishingCheck(
        blocked: true,
        warn: false,
        reason: 'Invalid URL',
        feedMode: mode,
        feedSource: source,
      );
    }

    final host = parsed.host.toLowerCase();
    // … empty-hostname check cut.

    if (!_isAllowedScheme(parsed.scheme)) {
      return PhishingCheck(
        blocked: true,
        warn: false,
        reason: 'Unsupported URL scheme: ${parsed.scheme}',
        feedMode: mode,
        feedSource: source,
      );
    }

    if (_isBlockedDomain(host, blockedDomains)) {
      return PhishingCheck(
        blocked: true,
        warn: false,
        reason: 'Known phishing domain',
        feedMode: mode,
        feedSource: source,
      );
    }

    if (host.contains('xn--')) {
      return PhishingCheck(
        blocked: true,
        warn: false,
        reason: 'Punycode domain blocked for safety',
        feedMode: mode,
        feedSource: source,
      );
    }

    final hostWithPath = '$host${parsed.path}'.toLowerCase();
    for (final keyword in _suspiciousKeywords) {
      if (hostWithPath.contains(keyword)) {
        return PhishingCheck(
          blocked: false,
          warn: true,
          reason: 'Suspicious keyword detected: $keyword',
          feedMode: mode,
          feedSource: source,
        );
      }
    }

    final typoTarget = _looksLikeTrustedTypo(host, trustedDomains);
    if (typoTarget != null) {
      return PhishingCheck(
        blocked: false,
        warn: true,
        reason: 'Domain looks similar to $typoTarget',
        feedMode: mode,
        feedSource: source,
      );
    }

    return PhishingCheck(
      blocked: false,
      warn: false,
      reason: '',
      feedMode: mode,
      feedSource: source,
    );
  }
}
