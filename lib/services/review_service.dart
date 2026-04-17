import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReviewResult { success, alreadySubmitted, failed }

class ReviewService {
  static const String _baseUrl = 'https://api.v3.sievesapp.com';
  static const String _reviewShownPrefix = 'review_shown_';

  /// Static upload token accepted ONLY by POST /file/upload/image.
  /// Replace the value here when the token rotates.
  static const String _uploadToken = 'd22fc27d96a51b45f2b44adc1ad482331a55783c9dd4e89bb919bfba0c2bb24c';

  /// Upload an image file and return the CDN URL, or null on failure.
  Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;
      final ext = fileName.split('.').last.toLowerCase();

      // Map extension → MIME type accepted by the server
      final mimeType = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png'           => 'image/png',
        'gif'           => 'image/gif',
        'webp'          => 'image/webp',
        _               => 'image/jpeg', // safe fallback
      };

      print('ReviewService [uploadImage] → POST $_baseUrl/file/upload/image');
      print('ReviewService [uploadImage] fileName: $fileName, mimeType: $mimeType, size: ${bytes.length} bytes');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/file/upload/image'),
      );

      // Static upload token — no Bearer auth on this route
      request.headers['x-upload-token'] = _uploadToken;
      print('ReviewService [uploadImage] x-upload-token: $_uploadToken');

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ReviewService [uploadImage] ← status: ${response.statusCode}');
      print('ReviewService [uploadImage] ← body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Try common response shapes: { url }, { data: { url } }, { path }, { link }
        final url = data['url'] ??
            data['link'] ??
            data['path'] ??
            (data['data'] is Map ? data['data']['url'] ?? data['data']['link'] ?? data['data']['path'] : null);
        print('ReviewService [uploadImage] ← extracted url: $url');
        return url as String?;
      } else {
        print('ReviewService [uploadImage] ✗ upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e, st) {
      print('ReviewService [uploadImage] ✗ exception: $e\n$st');
      return null;
    }
  }

  /// Submit the order review to the backend.
  Future<ReviewResult> submitReview({
    required int orderId,
    required int rating,
    String? comment,
    String? photoUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'order_id': orderId,
        'rating': rating,
      };
      if (comment != null && comment.isNotEmpty) body['comment'] = comment;
      if (photoUrl != null && photoUrl.isNotEmpty) body['photo_url'] = photoUrl;

      // Read phone number from SharedPreferences and normalise to 998xxxxxxxxx
      final prefs = await SharedPreferences.getInstance();
      String phone = prefs.getString('phoneNumber') ?? '';
      if (phone.startsWith('+')) phone = phone.substring(1);

      final uri = Uri.parse('$_baseUrl/order-review').replace(
        queryParameters: phone.isNotEmpty ? {'phone': phone} : null,
      );

      print('ReviewService [submitReview] → POST $uri');
      print('ReviewService [submitReview] → body: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-upload-token': _uploadToken,
        },
        body: jsonEncode(body),
      );

      print('ReviewService [submitReview] ← status: ${response.statusCode}');
      print('ReviewService [submitReview] ← body: ${response.body}');

      // Mark as shown regardless of API result
      await markReviewShown(orderId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReviewResult.success;
      }

      // Detect "already reviewed" 400
      if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        final message = (body['message'] as String? ?? '').toLowerCase();
        if (message.contains('already')) {
          return ReviewResult.alreadySubmitted;
        }
      }

      return ReviewResult.failed;
    } catch (e, st) {
      print('ReviewService [submitReview] ✗ exception: $e\n$st');
      return ReviewResult.failed;
    }
  }

  /// Returns true if the review prompt has already been shown for this order.
  Future<bool> hasReviewBeenShown(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_reviewShownPrefix$orderId') ?? false;
  }

  /// Mark that the review prompt was shown (or skipped) for this order.
  Future<void> markReviewShown(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_reviewShownPrefix$orderId', true);
  }
}
