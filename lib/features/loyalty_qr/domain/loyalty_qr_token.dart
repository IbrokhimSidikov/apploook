/// A minted in-store payment code, alive for [ttlSeconds] from the moment it
/// was received.
///
/// The countdown runs against [localExpiry], computed from the TTL at parse
/// time, rather than against the server's `expires_at` - a phone with a
/// skewed clock would otherwise show a "live" code the server has already
/// killed (or refresh a perfectly good one forever).
class LoyaltyQrToken {
  final String qrPayload;
  final DateTime localExpiry;
  final int ttlSeconds;
  final int spendable;
  final String cardNumber;

  const LoyaltyQrToken({
    required this.qrPayload,
    required this.localExpiry,
    required this.ttlSeconds,
    required this.spendable,
    required this.cardNumber,
  });

  factory LoyaltyQrToken.fromJson(Map<String, dynamic> json) {
    final ttl = int.tryParse(json['ttl_seconds']?.toString() ?? '') ?? 90;
    return LoyaltyQrToken(
      qrPayload: json['qr_payload']?.toString() ?? '',
      localExpiry: DateTime.now().add(Duration(seconds: ttl)),
      ttlSeconds: ttl,
      spendable: int.tryParse(json['spendable']?.toString() ?? '') ?? 0,
      cardNumber: json['card_number']?.toString() ?? '',
    );
  }

  int get secondsLeft {
    final left = localExpiry.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  bool get isExpired => secondsLeft <= 0;
}
