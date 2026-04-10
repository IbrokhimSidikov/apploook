import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

class ReviewBottomSheet extends StatefulWidget {
  final int orderId;

  const ReviewBottomSheet({required this.orderId});

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  double rating = 0;
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           Text(
            AppLocalizations.of(context).rateOrderTitle,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold
            ),
          ),

          const SizedBox(height: 16),

          // ⭐ Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: AppColors.cxFEC700,
                    size: 35,
                  ),
                  onPressed: () {
                    setState(() => rating = index + 1.0);
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // 📝 Comment
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).writeReview,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 📸 Upload (you can extend later)
          OutlinedButton(
            onPressed: () {
              // TODO: image picker
            },
            child: Text(AppLocalizations.of(context).addPhoto),
          ),

          const SizedBox(height: 20),

          // ✅ Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: rating == 0
                  ? null
                  : () {
                Navigator.pop(context, {
                  "rating": rating,
                  "comment": controller.text,
                });
              },
              child: Text(AppLocalizations.of(context).submit),
            ),
          ),
        ],
      ),
    );
  }
}