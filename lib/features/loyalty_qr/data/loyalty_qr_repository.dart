import 'package:apploook/features/loyalty_qr/domain/loyalty_qr_token.dart';
import 'package:apploook/services/loyalty_service.dart';

/// Fetches in-store payment codes over the existing loyalty session.
///
/// Thin by design: transport, auth and error mapping already live in
/// [LoyaltyService]; this layer only owns the domain shape.
class LoyaltyQrRepository {
  final LoyaltyService _service;

  LoyaltyQrRepository({LoyaltyService? service})
      : _service = service ?? LoyaltyService();

  /// Mints a fresh code. Throws [LoyaltySessionExpiredException] when the
  /// customer needs to sign in again.
  Future<LoyaltyQrToken> mint() async {
    return LoyaltyQrToken.fromJson(await _service.createQrToken());
  }
}
