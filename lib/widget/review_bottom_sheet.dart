import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/review_service.dart';

class ReviewBottomSheet extends StatefulWidget {
  final int orderId;

  const ReviewBottomSheet({required this.orderId, Key? key}) : super(key: key);

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final ReviewService _reviewService = ReviewService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isUploadingPhoto = false;
  bool _isSubmitting = false;
  bool _keyboardVisible = false;
  String? _uploadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _commentFocus.addListener(() {
      setState(() => _keyboardVisible = _commentFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _commentFocus.unfocus();
  }

  // ─── Photo picker ─────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    _dismissKeyboard();
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _selectedImage = file;
      _uploadedPhotoUrl = null;
      _isUploadingPhoto = true;
    });

    print('ReviewBottomSheet: picked image ${picked.path}');
    final url = await _reviewService.uploadImage(file);

    if (!mounted) return;
    setState(() {
      _uploadedPhotoUrl = url;
      _isUploadingPhoto = false;
    });

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo upload failed. You can still submit without it.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _uploadedPhotoUrl = null;
      _isUploadingPhoto = false;
    });
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    _dismissKeyboard();
    final loc = AppLocalizations.of(context);

    // Guard (also enforced by button disabled state)
    if (_rating == 0 || _isUploadingPhoto) return;

    setState(() => _isSubmitting = true);

    final success = await _reviewService.submitReview(
      orderId: widget.orderId,
      rating: _rating.toInt(),
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      photoUrl: _uploadedPhotoUrl,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? loc.reviewSubmitted : loc.reviewFailed),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _skip() async {
    _dismissKeyboard();
    await _reviewService.markReviewShown(widget.orderId);
    if (mounted) Navigator.of(context).pop();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return GestureDetector(
      // Tap outside comment → dismiss keyboard
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ──
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cxFEC700.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: AppColors.cxFEC700, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.rateOrderTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Order #${widget.orderId}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Close button
                    GestureDetector(
                      onTap: _skip,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Star rating ──
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _rating == 0
                            ? '⭐  ${loc.selectRating}'
                            : _ratingLabel(_rating.toInt()),
                        style: TextStyle(
                          fontSize: 13,
                          color: _rating == 0
                              ? Colors.grey.shade500
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = i < _rating;
                          return GestureDetector(
                            onTap: () => setState(() => _rating = i + 1.0),
                            child: AnimatedScale(
                              scale: filled ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Icon(
                                  filled
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: filled
                                      ? AppColors.cxFEC700
                                      : Colors.grey.shade300,
                                  size: 42,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Comment field ──
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    TextField(
                      controller: _commentController,
                      focusNode: _commentFocus,
                      maxLines: 4,
                      minLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _dismissKeyboard(),
                      decoration: InputDecoration(
                        hintText: loc.writeReview,
                        hintStyle:
                            TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.cxFEC700, width: 1.5),
                        ),
                      ),
                    ),
                    // Dismiss keyboard button — only visible while focused
                    if (_keyboardVisible)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: GestureDetector(
                          onTap: _dismissKeyboard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.keyboard_hide_rounded,
                                    size: 15, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('Done',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Photo section ──
                _buildPhotoSection(loc),

                const SizedBox(height: 20),

                // ── Submit button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        (_isSubmitting || _isUploadingPhoto || _rating == 0) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cxFEC700,
                      foregroundColor: const Color(0xFF0B0B0B),
                      disabledBackgroundColor:
                          AppColors.cxFEC700.withOpacity(0.45),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            loc.submit,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Skip ──
                TextButton(
                  onPressed: (_isSubmitting || _isUploadingPhoto) ? null : _skip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade500,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Text(loc.skip,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Photo section widget ──────────────────────────────────────────────────

  Widget _buildPhotoSection(AppLocalizations loc) {
    if (_selectedImage == null) {
      // Add photo button
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cxFEC700.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_photo_alternate_rounded,
                    color: AppColors.cxFEC700, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                loc.addPhoto,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'JPG, PNG up to 5 MB',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    // Photo selected — thumbnail row
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Thumbnail with overlay spinner
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _selectedImage!,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                ),
              ),
              if (_isUploadingPhoto)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Colors.black38,
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_isUploadingPhoto && _uploadedPhotoUrl != null)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 11),
                  ),
                ),
              if (!_isUploadingPhoto && _uploadedPhotoUrl == null)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 11),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Status + actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isUploadingPhoto)
                  Text(loc.uploadingPhoto,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600))
                else if (_uploadedPhotoUrl != null)
                  Text(
                    _uploadedPhotoUrl!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const Text(
                    'Upload failed',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Change
                    _actionChip(
                      icon: Icons.edit_rounded,
                      label: loc.changePhoto,
                      onTap: _isUploadingPhoto ? null : _pickImage,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    // Remove
                    _actionChip(
                      icon: Icons.delete_outline_rounded,
                      label: loc.removePhoto,
                      onTap: _isUploadingPhoto ? null : _removePhoto,
                      color: Colors.red.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return '😞  Terrible';
      case 2: return '😕  Poor';
      case 3: return '😐  Okay';
      case 4: return '😊  Good';
      case 5: return '🤩  Excellent!';
      default: return '';
    }
  }
}

