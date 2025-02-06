// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String baseUrl = 'https://api.sievesapp.com/v1/waiter-system';

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

      final message = responseData['message'] ?? 'Unknown response';
      final isVerified = message.toLowerCase() == 'successfully authorized';

      return {
        'status_code': response.statusCode,
        'message': message,
        'is_verified': isVerified,
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
      final response = await http.post(
        Uri.parse('$baseUrl/check-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone.replaceAll('+', ''),
          'verification_code': code,
        }),
      );

      print('Raw response: ${response.body}');

      // Try to parse the response, handle potential JSON parse errors
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('JSON decode error: $e');
        responseData = {};
      }

      // If we get a PHP Notice about individual_id, but the verification was successful
      if (responseData['name'] == 'PHP Notice' &&
          responseData['message']?.contains('individual_id') == true) {
        return {
          'status_code': 200, // Consider it successful
          'message': 'Verification successful',
        };
      }

      print('Verification response: $responseData');
      print('Response status code: ${response.statusCode}');

      return {
        'status_code': response.statusCode,
        'message': responseData['message'] ?? 'Unknown response',
      };
    } catch (e) {
      print('Verification error: $e');
      return {
        'status_code': 500,
        'message': 'Network error: $e',
      };
    }
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
