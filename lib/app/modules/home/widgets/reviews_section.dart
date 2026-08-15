import 'package:docwellness/app/models/review_model.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';

class ReviewsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final double averageRating;
  final ReviewModel? myReview;
  final String doctorName;
  final Future<bool> Function(int rating, String text) onSubmit;

  const ReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.myReview,
    required this.doctorName,
    required this.onSubmit,
  });

  void _openReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WriteReviewSheet(
        doctorName: doctorName,
        initialRating: myReview?.rating ?? 0,
        initialText: myReview?.text ?? '',
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Reviews',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: const Color(0xff530630),
              ),
              if (reviews.isNotEmpty)
                Row(
                  children: [
                    StarRow(rating: averageRating, size: 16),
                    const SizedBox(width: 6),
                    CustomText(
                      text: '${averageRating.toStringAsFixed(1)} (${reviews.length})',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: const Color(0xff4D5761),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openReviewSheet(context),
              icon: Icon(
                myReview == null ? Icons.rate_review_outlined : Icons.edit_outlined,
                size: 18,
                color: const Color(0xff851653),
              ),
              label: CustomText(
                text: myReview == null ? 'Write a Review' : 'Edit Your Review',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xff851653),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xff851653)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const CustomText(
                text: 'No reviews yet - be the first to share your experience.',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xff6C737F),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: reviews.map((r) => _ReviewCard(review: r)).toList(),
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final initial = review.patientName.isNotEmpty ? review.patientName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xffFCE7F6),
                child: CustomText(
                  text: initial,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xff851653),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomText(
                  text: review.patientName,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xff530630),
                ),
              ),
              StarRow(rating: review.rating.toDouble(), size: 14),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            CustomText(
              text: review.text,
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: const Color(0xff4D5761),
              height: 1.4,
            ),
          ],
        ],
      ),
    );
  }
}

/// Read-only star display, filled up to [rating] (rounded to the nearest
/// whole star - fractional averages like 4.7 read fine rounded for a
/// 5-icon row like this).
class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const StarRow({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final filled = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < filled ? Icons.star : Icons.star_border,
          size: size,
          color: const Color(0xffF670CA),
        );
      }),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  final String doctorName;
  final int initialRating;
  final String initialText;
  final Future<bool> Function(int rating, String text) onSubmit;

  const _WriteReviewSheet({
    required this.doctorName,
    required this.initialRating,
    required this.initialText,
    required this.onSubmit,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late int _rating = widget.initialRating;
  late final TextEditingController _textController =
      TextEditingController(text: widget.initialText);
  bool _submitting = false;

  Future<void> _submit() async {
    if (_rating == 0) {
      showAppToast(context, message: 'Please select a star rating', type: AppToastType.error);
      return;
    }
    setState(() => _submitting = true);
    final success = await widget.onSubmit(_rating, _textController.text.trim());
    setState(() => _submitting = false);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      showAppToast(context, message: 'Could not save your review. Please try again.', type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          CustomText(
            text: 'Rate ${widget.doctorName}',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xff530630),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starIndex <= _rating ? Icons.star : Icons.star_border,
                      size: 36,
                      color: const Color(0xffF670CA),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _textController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)',
              filled: true,
              fillColor: const Color(0xffFEF6FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffFCE7F6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffFCE7F6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff851653)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff851653),
                disabledBackgroundColor: const Color(0xffBE7BA4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
