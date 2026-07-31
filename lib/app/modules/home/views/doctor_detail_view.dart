import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/article_model.dart';
import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/app/models/review_model.dart';
import 'package:docwellness/app/models/social_media_post_model.dart';
import 'package:docwellness/app/modules/home/services/doctor_profile_service.dart';
import 'package:docwellness/app/modules/home/widgets/articles_section.dart';
import 'package:docwellness/app/modules/home/widgets/reviews_section.dart';
import 'package:docwellness/app/modules/home/widgets/social_media_section.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

// Shown whenever the dietician hasn't written their own bio yet (see
// dieticianProfile.bio - empty until she fills it in via the "Bio /
// Description" field on the dietician app's own profile screen). A warm,
// first-person placeholder reads far better on a real device than "No bio
// available", and gives her a draft to edit rather than a blank field to
// fill from scratch.
const String _placeholderBio =
    "I didn't get into nutrition because of a textbook - I got into it "
    "because I've watched too many people chase quick fixes that leave "
    "them more frustrated (and more restricted) than when they started. "
    "Crash diets, calorie obsession, guilt around food - none of that is "
    "sustainable, and none of it is the point.\n\n"
    "What I care about is helping you build a way of eating that actually "
    "fits your life - one that still has room for the foods you love, the "
    "schedule you actually have, and the goals that matter to you. No "
    "extreme rules, no shame, just a plan we build together and adjust as "
    "we go.\n\n"
    "I'm not just here to hand you a meal plan and disappear. I'm here for "
    "the questions, the slow weeks, and the wins worth celebrating.";

const String _placeholderPullQuote =
    "Real, lasting change doesn't come from restriction - it comes from a "
    "plan that fits your actual life.";

class DoctorDetailView extends StatefulWidget {
  const DoctorDetailView({super.key});

  @override
  State<DoctorDetailView> createState() => _DoctorDetailViewState();
}

class _DoctorDetailViewState extends State<DoctorDetailView> {
  final DoctorProfileService _service = DoctorProfileService();

  DoctorProfileModel? doctor;
  bool isLoading = true;

  List<SocialMediaPostModel> youtubePosts = [];
  List<SocialMediaPostModel> instagramPosts = [];
  List<ArticleModel> articles = [];
  List<ReviewModel> reviews = [];
  double averageRating = 0;
  ReviewModel? myReview;

  @override
  void initState() {
    super.initState();
    _fetchDoctorProfile();
    _fetchSocialMedia();
    _fetchArticles();
    _fetchReviews();
  }

  Future<void> _fetchDoctorProfile() async {
    final profile = await _service.getAssignedDoctorProfile();
    if (mounted) {
      setState(() {
        doctor = profile;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSocialMedia() async {
    final result = await _service.getSocialMediaPosts();
    if (!mounted) return;
    setState(() {
      youtubePosts = result['youtube'] ?? [];
      instagramPosts = result['instagram'] ?? [];
    });
  }

  Future<void> _fetchArticles() async {
    final result = await _service.getArticles();
    if (!mounted) return;
    setState(() => articles = result);
  }

  Future<void> _fetchReviews() async {
    final result = await _service.getReviews();
    if (!mounted) return;
    setState(() {
      reviews = result['reviews'] as List<ReviewModel>;
      averageRating = result['averageRating'] as double;
      myReview = result['myReview'] as ReviewModel?;
    });
  }

  Future<bool> _submitReview(int rating, String text) async {
    final success = await _service.submitReview(rating: rating, text: text);
    if (success) await _fetchReviews();
    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        title: const Text('About Doctor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff851653)),
            )
          : doctor == null
          ? const Center(child: Text('Could not load doctor profile'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-bleed photo carousel - replaces the old generic
                  // circular-avatar-placeholder header. Falls back to her
                  // single profileImage (or a plain placeholder) when she
                  // hasn't added gallery photos yet, so the page never
                  // shows an empty gap at the top. Name/specialization are
                  // overlaid on the image itself instead of sitting in
                  // their own separate header block.
                  _PhotoCarousel(
                    images: doctor!.galleryImages.isNotEmpty
                        ? doctor!.galleryImages
                        : (doctor!.profileImage.isNotEmpty ? [doctor!.profileImage] : []),
                    name: doctor!.displayName,
                    specialization: doctor!.specialization,
                  ),

                  const SizedBox(height: 24),

                  // My Story - leads with the personal, empathetic
                  // narrative (why she coaches, her philosophy) rather
                  // than credentials, so the page reads like getting to
                  // know a person instead of scanning a CV.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomText(
                      text: 'My Story',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: const Color(0xff530630),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomText(
                      text: doctor!.bio.isNotEmpty
                          ? doctor!.bio
                          : _placeholderBio,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: const Color(0xff4D5761),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pull-quote highlight - a single distilled line of her
                  // philosophy, set apart visually so it reads as a
                  // takeaway rather than more paragraph text.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF6FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffFCE7F6)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: '“',
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                            color: const Color(0xffF670CA),
                            height: 1,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomText(
                              text: _placeholderPullQuote,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: const Color(0xff851653),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Credentials - kept, but demoted to compact supporting
                  // chips after the story instead of leading with them.
                  if (doctor!.age != null ||
                      doctor!.experience > 0 ||
                      doctor!.qualification.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          if (doctor!.age != null)
                            _buildInfoCard(
                              icon: Icons.cake_outlined,
                              label: 'Age',
                              value: '${doctor!.age} yrs',
                            ),
                          if (doctor!.experience > 0) ...[
                            const SizedBox(width: 12),
                            _buildInfoCard(
                              icon: Icons.work_outline,
                              label: 'Experience',
                              value: '${doctor!.experience} yrs',
                            ),
                          ],
                          if (doctor!.qualification.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            _buildInfoCard(
                              icon: Icons.school_outlined,
                              label: 'Degree',
                              value: doctor!.qualification,
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  SocialMediaSection(youtube: youtubePosts, instagram: instagramPosts),

                  const SizedBox(height: 28),

                  ReviewsSection(
                    reviews: reviews,
                    averageRating: averageRating,
                    myReview: myReview,
                    doctorName: doctor!.displayName,
                    onSubmit: _submitReview,
                  ),

                  const SizedBox(height: 28),

                  ArticlesSection(articles: articles),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffFDF2FA)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xff851653), size: 24),
            const SizedBox(height: 8),
            CustomText(
              text: label,
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: const Color(0xff4D5761),
            ),
            const SizedBox(height: 4),
            CustomText(
              text: value,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xff530630),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-bleed (edge-to-edge, no side padding/rounding) auto-scrolling photo
/// carousel that IS the About Doctor page's header - replaces the old
/// generic circular-avatar-placeholder block. Advances every 4s and loops;
/// name/specialization are overlaid at the bottom (gradient + white text)
/// instead of living in a separate header underneath. Falls back to a
/// plain placeholder (still carrying the name overlay) when there are no
/// photos at all, so identity is never lost even before any are uploaded.
class _PhotoCarousel extends StatefulWidget {
  final List<String> images;
  final String name;
  final String specialization;

  const _PhotoCarousel({
    required this.images,
    required this.name,
    required this.specialization,
  });

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  late final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted) return;
    final next = (_page + 1) % widget.images.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.images.isEmpty
              ? Container(color: const Color(0xffFCE7F6))
              : PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) => CachedNetworkImage(
                    imageUrl: widget.images[index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xffFCE7F6),
                      child: const Icon(Icons.image_outlined, size: 48, color: Color(0xff9DA4AE)),
                    ),
                  ),
                ),

          // Bottom gradient so white overlay text stays legible over any photo.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Color(0xB3000000)],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: widget.images.length > 1 ? 26 : 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: widget.name,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: Colors.white,
                ),
                if (widget.specialization.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    text: widget.specialization,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),

          if (widget.images.length > 1)
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: Row(
                children: List.generate(widget.images.length, (i) {
                  final isActive = i == _page;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 4),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
