import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apploook/models/loyalty.dart';

/// HTTP client for the sieves-api-v3 `/loyalty` endpoints.
///
/// Unlike the review and order-history calls, loyalty is not reachable with a
/// phone number and the shared static token: it moves money, so every route
/// needs a session token minted against the customer's own SMS code. The
/// static token is used exactly once, to mint that session.
class LoyaltyService {
  static final LoyaltyService _instance = LoyaltyService._internal();
  factory LoyaltyService() => _instance;
  LoyaltyService._internal();

  static const String _baseUrl = 'https://api.v3.sievesapp.com';

  /// Same static client token the review upload uses. Replace when it rotates.
  static const String _staticToken =
      'd22fc27d96a51b45f2b44adc1ad482331a55783c9dd4e89bb919bfba0c2bb24c';

  static const String _tokenKey = 'loyalty_token';
  static const String _tokenExpiryKey = 'loyalty_token_expiry';
  static const String _deviceIdKey = 'loyalty_device_id';

  static const Duration _timeout = Duration(seconds: 15);

  String? _cachedToken;

  /// Why the last session mint failed, for the profile card and for support.
  /// A failed mint is otherwise indistinguishable from "not activated yet",
  /// which is exactly how a phone-format mismatch stayed invisible.
  String? lastMintError;

  // -------------------------------------------------------------------
  // Session
  // -------------------------------------------------------------------

  Future<String?> _readToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    final expiry = prefs.getString(_tokenExpiryKey);
    if (expiry != null) {
      final parsed = DateTime.tryParse(expiry);
      if (parsed != null && parsed.isBefore(DateTime.now())) {
        await clearSession();
        return null;
      }
    }
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<bool> hasSession() async => (await _readToken()) != null;

  /// True when the customer is signed in to the app but holds no loyalty
  /// session yet.
  ///
  /// This is the normal state for anyone who signed in before cashback
  /// existed: the token can only be minted against a live SMS code, so an
  /// existing login cannot be upgraded silently. Without surfacing it, those
  /// customers see no cashback UI at all and no request is ever sent.
  Future<bool> needsActivation() async {
    if (await hasSession()) return false;
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    return phone != null && phone.isNotEmpty;
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      // Not a hardware id - just a stable per-install value so the server can
      // tell one device's sessions apart.
      id = '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
          '-${identityHashCode(this).toRadixString(36)}';
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  /// Exchanges the SMS code the customer just entered for a session token.
  /// Call this immediately after verification succeeds, while the code is
  /// still the one stored server-side.
  Future<bool> createSession({
    required String phone,
    required String verificationCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/loyalty/sessions'),
            headers: {
              'Content-Type': 'application/json',
              'x-upload-token': _staticToken,
            },
            body: json.encode({
              'phone': phone.replaceAll('+', ''),
              'verification_code': verificationCode.trim(),
              'device_id': await _deviceId(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        lastMintError = 'HTTP ${response.statusCode}: ${response.body}';
        debugPrint('╔══ LOYALTY: session mint FAILED ══');
        debugPrint('║ POST $_baseUrl/loyalty/sessions');
        debugPrint('║ phone sent: ${phone.replaceAll('+', '')}');
        debugPrint('║ status: ${response.statusCode}');
        debugPrint('║ body: ${response.body}');
        debugPrint('╚══════════════════════════════════');
        return false;
      }

      return _storeSession(json.decode(utf8.decode(response.bodyBytes)));
    } catch (e) {
      lastMintError = e.toString();
      debugPrint('╔══ LOYALTY: session mint ERROR ══');
      debugPrint('║ $e');
      debugPrint('╚═════════════════════════════════');
      return false;
    }
  }

  Future<bool> _storeSession(Map<String, dynamic> data) async {
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (data['expires_at'] != null) {
      await prefs.setString(_tokenExpiryKey, data['expires_at'].toString());
    }
    // profile.dart has always read this key, but nothing ever wrote it.
    if (data['individual_id'] != null) {
      final id = int.tryParse(data['individual_id'].toString());
      if (id != null) await prefs.setInt('individual_id', id);
    }
    _cachedToken = token;
    lastMintError = null;
    debugPrint('LOYALTY: session minted, individual ${data['individual_id']} '
        'card ${data['card_number']}');
    return true;
  }

  /// Re-establishes the session for a customer v1 has already verified - no
  /// SMS code. Called on launch, which is what makes activation automatic: a
  /// customer who signed in before cashback existed, or whose mint at
  /// verification failed transiently, gets a card without doing anything.
  Future<bool> resumeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    if (phone == null || phone.isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/loyalty/sessions/resume'),
            headers: {
              'Content-Type': 'application/json',
              'x-upload-token': _staticToken,
            },
            body: json.encode({
              'phone': phone.replaceAll('+', ''),
              'device_id': await _deviceId(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        lastMintError = 'resume HTTP ${response.statusCode}: ${response.body}';
        debugPrint('╔══ LOYALTY: session resume FAILED ══');
        debugPrint('║ phone sent: ${phone.replaceAll('+', '')}');
        debugPrint('║ status: ${response.statusCode}');
        debugPrint('║ body: ${response.body}');
        debugPrint('╚════════════════════════════════════');
        return false;
      }
      return _storeSession(json.decode(utf8.decode(response.bodyBytes)));
    } catch (e) {
      lastMintError = e.toString();
      debugPrint('LOYALTY: session resume error $e');
      return false;
    }
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  /// Best-effort server-side revoke, then local clear. Call on logout.
  Future<void> endSession() async {
    final token = await _readToken();
    if (token != null) {
      try {
        await http.delete(
          Uri.parse('$_baseUrl/loyalty/sessions'),
          headers: {'x-loyalty-token': token},
        ).timeout(_timeout);
      } catch (_) {
        // The local token is cleared regardless; a stale server row expires.
      }
    }
    await clearSession();
  }

  // -------------------------------------------------------------------
  // Transport
  // -------------------------------------------------------------------

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _readToken();
    if (token == null) throw LoyaltySessionExpiredException();

    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      'x-loyalty-token': token,
    };
    final encoded = body == null ? null : json.encode(body);

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: encoded)
              .timeout(_timeout);
          break;
        default:
          throw UnsupportedError('Unsupported method $method');
      }
    } on SocketException {
      throw Exception('No connection');
    }

    if (response.statusCode == 401) {
      await clearSession();
      throw LoyaltySessionExpiredException();
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 409) {
      final payload = decoded is Map ? decoded.cast<String, dynamic>() : {};
      // Both mean "the numbers on screen are no longer right": the balance
      // moved, or the server found the cached balance is not backed by the
      // ledger. Either way the response carries a fresh quote, and the right
      // reaction is the same - re-render and let the customer confirm again,
      // never silently place the order at a different price.
      const requote = {'LOYALTY_QUOTE_STALE', 'LOYALTY_BALANCE_UNBACKED'};
      if (requote.contains(payload['code'])) {
        final quoteJson = (payload['quote'] as Map?)?.cast<String, dynamic>();
        throw LoyaltyQuoteStaleException(
          quoteJson == null ? null : LoyaltyQuote.fromJson(quoteJson),
        );
      }
      throw Exception(payload['message']?.toString() ?? 'Conflict');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['message']?.toString() ?? response.body)
          : response.body;
      throw Exception('Loyalty request failed (${response.statusCode}): $message');
    }

    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{'data': decoded};
  }

  // -------------------------------------------------------------------
  // Endpoints
  // -------------------------------------------------------------------

  Future<LoyaltySummary> fetchSummary() async {
    return LoyaltySummary.fromJson(await _request('GET', '/loyalty/card'));
  }

  Future<List<LoyaltyTransaction>> fetchTransactions({
    int page = 1,
    int limit = 30,
  }) async {
    final data =
        await _request('GET', '/loyalty/transactions?page=$page&limit=$limit');
    final rows = (data['data'] as List?) ?? const [];
    return rows
        .map((r) => LoyaltyTransaction.fromJson(
            (r as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Prices a basket. Stateless and cheap - safe to call as the slider moves.
  Future<LoyaltyQuote> quote({
    required int subtotal,
    required int orderTypeId,
    int deliveryFee = 0,
    int requestedPoints = 0,
  }) async {
    final data = await _request('POST', '/loyalty/quote', body: {
      'subtotal': subtotal,
      'order_type_id': orderTypeId,
      'delivery_fee': deliveryFee,
      'requested_points': requestedPoints,
    });
    return LoyaltyQuote.fromJson(data);
  }

  /// Reserves the points. Must run BEFORE the order is sent, so the returned
  /// [LoyaltyHold.orderNoteRef] can be written into the order comment.
  Future<LoyaltyHold> createHold({
    required int subtotal,
    required int orderTypeId,
    int deliveryFee = 0,
    int requestedPoints = 0,
    String? externalOrderId,
    String? idempotencyKey,
  }) async {
    final data = await _request('POST', '/loyalty/holds', body: {
      'subtotal': subtotal,
      'order_type_id': orderTypeId,
      'delivery_fee': deliveryFee,
      'requested_points': requestedPoints,
      if (externalOrderId != null) 'external_order_id': externalOrderId,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    });
    return LoyaltyHold.fromJson(data);
  }

  Future<void> commitHold(
    int holdId, {
    String? externalOrderId,
    int? orderId,
  }) async {
    await _request('POST', '/loyalty/holds/$holdId/commit', body: {
      if (externalOrderId != null) 'external_order_id': externalOrderId,
      if (orderId != null) 'order_id': orderId,
    });
  }

  Future<void> releaseHold(int holdId) async {
    await _request('POST', '/loyalty/holds/$holdId/release');
  }

  /// Mints an in-store payment QR. Raw map on purpose: the shape belongs to
  /// the loyalty_qr feature, whose repository turns it into a domain model.
  Future<Map<String, dynamic>> createQrToken() =>
      _request('POST', '/loyalty/qr');
}
