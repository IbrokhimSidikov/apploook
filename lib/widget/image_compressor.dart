import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImageCompressor {
  static Future<Image> compressNetworkImage(String imageUrl, {
    int targetWidth = 300,  // Adjust this based on your UI needs
    int targetHeight = 300, // Adjust this based on your UI needs
    int quality = 85,      // Adjust quality (0-100)
  }) async {
    try {
      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      // Compress the image
      final Uint8List? compressedData = await FlutterImageCompress.compressWithList(
        response.bodyBytes,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: quality,
      );

      if (compressedData == null) {
        throw Exception('Failed to compress image');
      }

      // Create Image widget from compressed data
      return Image.memory(
        compressedData,
        fit: BoxFit.contain,
      );
    } catch (e) {
      print('Error compressing image: $e');
      // Return original image if compression fails
      return Image.network(imageUrl, fit: BoxFit.contain);
    }
  }
}