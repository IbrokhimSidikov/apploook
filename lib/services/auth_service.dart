// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  final String baseUrl = 'https://api.sievesapp.com/v1/waiter-system';
  // Make verification code static so it persists across instances
  static String? currentVerificationCode;

  /// Individual returned by authorize-individual, needed by check-verification
  /// and by logout. Static for the same reason as the code above: the pages
  /// construct their own AuthService instances.
  static int? currentIndividualId;

  Future<Map<String, dynamic>> authorizeUser(
      String phone, String firstName) async {
    try {
      print('Authorizing user - Phone: $phone, Name: $firstName');
      final response = await http.post(
        Uri.parse('$baseUrl/authorize-individual'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone.replaceAll('+', ''),
          'first_name': firstName,
        }),
      );

      final responseData = json.decode(response.body);
      print('Authorization response: $responseData');

      // Store the verification code
      currentVerificationCode = responseData['verification_code']?.toString();
      currentIndividualId =
          int.tryParse('${responseData['individual_id'] ?? ''}');
      print('Stored verification code: $currentVerificationCode');
      print('AuthService instance hash: ${identityHashCode(this)}');

      final message = responseData['message'] ?? 'Unknown response';
      final isVerified = message.toLowerCase() == 'successfully authorized';

      return {
        'status_code': response.statusCode,
        'message': message,
        'is_verified': isVerified,
        'verification_code': currentVerificationCode,
        'individual_id': currentIndividualId,
      };
    } catch (e) {
      print('Authorization error: $e');
      return {
        'status_code': 500,
        'message': 'Network error: $e',
      };
    }
  }

  /// Confirms the OTP.
  ///
  /// This must go through the server: `check-verification` is what sets
  /// t_individual.isVerified to 1. The previous implementation compared the
  /// code locally against the value authorize-individual had echoed back,
  /// which let the customer in but left the column at 0 permanently - so the
  /// "already verified" shortcut never fired and logout had nothing to reset.
  Future<Map<String, dynamic>> verifyCode(String phone, String code) async {
    final individualId = currentIndividualId;

    if (individualId != null) {
      try {
        print('Verifying code with server - individual: $individualId');
        final response = await http.post(
          Uri.parse('$baseUrl/check-verification'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'verification_code': code.trim(),
            'individual_id': individualId,
          }),
        );

        final data = json.decode(response.body);
        print('check-verification response: $data');

        if (data['status_code'] == 200) {
          // Only persist the id once the server has accepted the code, so an
          // abandoned verification leaves nothing behind.
          await _persistIndividualId(individualId);
          return {
            'status_code': 200,
            'message': 'Verification successful',
            'individual_id': individualId,
          };
        }

        // The server rejected it. Do not fall through to the local compare -
        // it is the weaker check and would contradict the source of truth.
        return {
          'status_code': 401,
          'message': data['message'] ?? 'Invalid verification code',
        };
      } catch (e) {
        print('check-verification failed, falling back to local compare: $e');
        // Network trouble only. Fall through so a flaky connection cannot lock
        // a customer out; isVerified stays 0 and is corrected on next login.
      }
    }

    if (code == currentVerificationCode) {
      if (individualId != null) await _persistIndividualId(individualId);
      return {
        'status_code': 200,
        'message': 'Verification successful',
        'individual_id': individualId,
      };
    }

    return {
      'status_code': 401,
      'message': 'Invalid verification code',
    };
  }

  Future<void> _persistIndividualId(int individualId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('individual_id', individualId);
  }

  void clearVerificationCode() {
    print('Clearing verification code. Current code: $currentVerificationCode');
    print('AuthService instance hash: ${identityHashCode(this)}');
    currentVerificationCode = null;
    print('Verification code cleared. New value: $currentVerificationCode');
  }

  /// Clears the server-side verification flag on sign-out.
  ///
  /// The route is `GET test` and actionTest reads query parameters, so the
  /// previous POST-with-a-JSON-body delivered no individual_id at all and the
  /// endpoint always answered "Individual ID is required".
  Future<bool> logout(String individualId) async {
    try {
      final uri = Uri.parse('$baseUrl/test')
          .replace(queryParameters: {'individual_id': individualId});
      print('Logging out user with ID: $individualId -> $uri');

      final response = await http.get(uri);
      print('Logout response: ${response.body}');

      currentIndividualId = null;
      currentVerificationCode = null;

      if (response.statusCode != 200) return false;
      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}
