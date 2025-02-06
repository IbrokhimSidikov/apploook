// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String baseUrl = 'https://api.sievesapp.com/v1/waiter-system';
  // Make verification code static so it persists across instances
  static String? currentVerificationCode;

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
      print('Stored verification code: $currentVerificationCode');
      print('AuthService instance hash: ${identityHashCode(this)}');

      final message = responseData['message'] ?? 'Unknown response';
      final isVerified = message.toLowerCase() == 'successfully authorized';

      return {
        'status_code': response.statusCode,
        'message': message,
        'is_verified': isVerified,
        'verification_code': currentVerificationCode,
      };
    } catch (e) {
      print('Authorization error: $e');
      return {
        'status_code': 500,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> verifyCode(String phone, String code) async {
    try {
      print('Verifying code - Phone: $phone, Code: $code');
      print('Stored verification code: $currentVerificationCode');
      print('AuthService instance hash: ${identityHashCode(this)}');

      // Compare with stored verification code
      if (code == currentVerificationCode) {
        return {
          'status_code': 200,
          'message': 'Verification successful',
        };
      }

      return {
        'status_code': 401,
        'message': 'Invalid verification code',
      };
    } catch (e) {
      print('Verification error: $e');
      return {
        'status_code': 500,
        'message': 'Network error: $e',
      };
    }
  }

  void clearVerificationCode() {
    print('Clearing verification code. Current code: $currentVerificationCode');
    print('AuthService instance hash: ${identityHashCode(this)}');
    currentVerificationCode = null;
    print('Verification code cleared. New value: $currentVerificationCode');
  }

  Future<bool> logout(String individualId) async {
    try {
      print('Logging out user with ID: $individualId');
      final response = await http.post(
        Uri.parse('$baseUrl/test'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'individual_id': individualId,
        }),
      );

      print('Logout response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}
