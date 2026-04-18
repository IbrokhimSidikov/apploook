import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/review_service.dart';

class ReviewBottomSheet extends StatefulWidget {
  final int orderId;
  /// Optional order data map (from order history API) to show a compact summary.
  final Map<String, dynamic>? orderData;

  const ReviewBottomSheet({required this.orderId, this.orderData, Key? key}) : super(key: key);

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
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
      if (_commentFocus.hasFocus) {
        // After keyboard finishes animating, scroll so the field is visible
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => _commentFocus.unfocus();

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
    if (_rating == 0 || _isUploadingPhoto) return;

    setState(() => _isSubmitting = true);

    final result = await _reviewService.submitReview(
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

    _showResultSnackbar(context, result, loc);
  }

  void _showResultSnackbar(
      BuildContext context, ReviewResult result, AppLocalizations loc) {
    final (String message, Color bg, IconData icon) = switch (result) {
      ReviewResult.success => (
          loc.reviewSubmitted,
          AppColors.cx1B8A4C,
          Icons.check_circle_rounded,
        ),
      ReviewResult.alreadySubmitted => (
          loc.reviewAlreadySubmitted,
          AppColors.cx1565C0,
          Icons.info_rounded,
        ),
      ReviewResult.failed => (
          loc.reviewFailed,
          AppColors.cxC62828,
          Icons.error_rounded,
        ),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        controller: _scrollController,
        // Bottom padding expands with the keyboard so content scrolls above it
        padding: EdgeInsets.fromLTRB(20, 12, 20, keyboardHeight + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
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

            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cxFEC700.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.cxFEC700, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.rateOrderTitle,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    Text('Order #${widget.orderId}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
                const Spacer(),
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

            // ── Compact order snapshot ────────────────────────────────────
            if (widget.orderData != null) ...[
              _buildOrderSnapshot(widget.orderData!),
              const SizedBox(height: 16),
            ],

            // ── Star rating ───────────────────────────────────────────────
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
                        : _ratingLabel(_rating.toInt(), context),
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

            // ── Comment field ─────────────────────────────────────────────
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
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14),
                    helperText: 'Emoji are not supported',
                    helperStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 11),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding:
                        const EdgeInsets.fromLTRB(14, 14, 14, 40),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.cxFEC700, width: 1.5),
                    ),
                  ),
                ),
                // Done button — visible only while keyboard is open
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

            // ── Photo section ─────────────────────────────────────────────
            _buildPhotoSection(loc),
            const SizedBox(height: 20),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (_isSubmitting || _isUploadingPhoto || _rating == 0)
                        ? null
                        : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cxFEC700,
                  foregroundColor: AppColors.cx0B0B0B,
                  disabledBackgroundColor:
                      AppColors.cxFEC700.withValues(alpha: 0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
                    : Text(loc.submit,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),

            // ── Skip ──────────────────────────────────────────────────────
            TextButton(
              onPressed:
                  (_isSubmitting || _isUploadingPhoto) ? null : _skip,
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
    );
  }

  // ─── Compact order snapshot ──────────────────────────────────────────────

  Widget _buildOrderSnapshot(Map<String, dynamic> order) {
    final items = (order['order_items'] as List<dynamic>? ?? []);
    final branch = order['branch_name'] as String? ?? '';
    final timeStr = order['time'] as String?;
    String formattedDate = '';
    if (timeStr != null) {
      try {
        final dt = DateTime.parse(timeStr).toLocal();
        formattedDate = DateFormat('dd MMM · HH:mm').format(dt);
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cxFEC700.withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cxFEC700.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header bar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cxFEC700.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.cxFEC700.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 14, color: AppColors.cxFEC700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branch,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (formattedDate.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(formattedDate,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
              ],
            ),
          ),

          // ── Items ────────────────────────────────────────────────────────
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  ...items.take(4).map((item) {
                    final name = item['name'] as String? ??
                        item['product_name'] as String? ??
                        '–';
                    final qty = item['quantity'] ?? item['count'] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Quantity pill
                          Container(
                            width: 26,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.cxFEC700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '×$qty',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (items.length > 4)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${items.length - 4} more items',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Photo section ────────────────────────────────────────────────────────

  Widget _buildPhotoSection(AppLocalizations loc) {
    if (_selectedImage == null) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cxFEC700.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_photo_alternate_rounded,
                    color: AppColors.cxFEC700, size: 26),
              ),
              const SizedBox(height: 8),
              Text(loc.addPhoto,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const SizedBox(height: 2),
              Text('JPG, PNG up to 5 MB',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    // Photo selected
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_selectedImage!,
                    width: 68, height: 68, fit: BoxFit.cover),
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
                              strokeWidth: 2.5, color: Colors.white),
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
                        color: Colors.green, shape: BoxShape.circle),
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
                        color: Colors.orange, shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Status + action chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isUploadingPhoto)
                  Text(loc.uploadingPhoto,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600))
                else if (_uploadedPhotoUrl != null)
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _selectedImage!.path.split('/').last,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  const Text('Upload failed',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _actionChip(
                      icon: Icons.edit_rounded,
                      label: loc.changePhoto,
                      onTap: _isUploadingPhoto ? null : _pickImage,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
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

  String _ratingLabel(int r, BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (r) {
      case 1: return l.ratingTerrible;
      case 2: return l.ratingPoor;
      case 3: return l.ratingOkay;
      case 4: return l.ratingGood;
      case 5: return l.ratingExcellent;
      default: return '';
    }
  }
}

