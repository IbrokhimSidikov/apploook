import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static const String _baseUrl = 'https://api.v3.sievesapp.com';
  static const String _reviewShownPrefix = 'review_shown_';

  /// Upload an image file and return the CDN URL, or null on failure.
  Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;

      print('ReviewService [uploadImage] → POST $_baseUrl/file/upload/image');
      print('ReviewService [uploadImage] fileName: $fileName, size: ${bytes.length} bytes');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/file/upload/image'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
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
  Future<bool> submitReview({
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

      print('ReviewService [submitReview] → POST $_baseUrl/order-review');
      print('ReviewService [submitReview] → body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/order-review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('ReviewService [submitReview] ← status: ${response.statusCode}');
      print('ReviewService [submitReview] ← body: ${response.body}');

      // Mark as shown regardless of API result
      await markReviewShown(orderId);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      print('ReviewService [submitReview] ✗ exception: $e\n$st');
      return false;
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
