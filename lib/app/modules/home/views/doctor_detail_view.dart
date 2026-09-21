import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/article_model.dart';
import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/app/models/review_model.dart';
import 'package:docwellness/app/models/social_media_post_model.dart';
import 'package:docwellness/app/modules/home/services/doctor_profile_service.dart';
import 'package:docwellness/app/modules/home/widgets/articles_section.dart';
import 'package:docwellness/app/modules/home/widgets/doctor_hero_tag.dart';
import 'package:docwellness/app/modules/home/widgets/reviews_section.dart';
import 'package:docwellness/app/modules/home/widgets/social_media_section.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/motion.dart';
import 'package:docwellness/utils/common_widgets/shimmer_box.dart';
import 'package:flutter/foundation.dart';
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

// Falls back only when the dietician hasn't set dieticianProfile.pullQuote
// yet (see the "Philosophy Quote" field on the dietician app's profile
// screen) - once she does, her own line replaces this everywhere.
const String _placeholderPullQuote =
    "Real, lasting change doesn't come from restriction - it comes from a "
    "plan that fits your actual life.";

class DoctorDetailView extends StatefulWidget {
  const DoctorDetailView({super.key});

  @override
  State<DoctorDetailView> createState() => _DoctorDetailViewState();
}

// Header photo's collapsed height once the SliverAppBar has scrolled all
// the way up - the collapse-progress math below is relative to this and
// _kExpandedHeaderHeight, so both the crossfade and the SliverAppBar's own
// expandedHeight stay in lockstep instead of two magic numbers drifting
// apart.
const double _kExpandedHeaderHeight = 340;

class _DoctorDetailViewState extends State<DoctorDetailView> {
  final DoctorProfileService _service = DoctorProfileService();
  // Drives a deterministic crossfade between the carousel's own name/
  // specialization overlay (visible while expanded) and the compact app
  // bar's title (visible once collapsed) - see _collapseListener's doc
  // comment for why this replaces FlexibleSpaceBar's own built-in title
  // fade.
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _collapseProgress = ValueNotifier(0);

  DoctorProfileModel? doctor;
  bool isLoading = true;
  bool _bioExpanded = false;

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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _collapseProgress.dispose();
    super.dispose();
  }

  // Both the carousel's own bottom-anchored name overlay and the SliverAppBar's
  // built-in collapsing title were independently deciding when to be visible -
  // FlexibleSpaceBar's title fades in during the back half of the collapse
  // while the parallax-scrolled photo (with the overlay baked into it) was
  // still sliding the SAME text into that exact spot, so for a stretch of the
  // scroll both were on screen together (see the reported "Dr. Tejasvini"/
  // "Dr. T..." overlap). Replacing both with one shared 0..1 progress value -
  // the carousel overlay uses (1 - progress), the compact title uses
  // progress - makes them complementary by construction: there is no offset
  // at which both can be more than half-visible.
  void _onScroll() {
    final maxCollapse = _kExpandedHeaderHeight - kToolbarHeight;
    final progress = (_scrollController.offset / maxCollapse).clamp(0.0, 1.0);
    _collapseProgress.value = progress;
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
      body: isLoading
          ? const _LoadingSkeleton()
          : doctor == null
          ? Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _GlassIconButton(
                        icon: Icons.arrow_back,
                        dark: true,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Center(child: Text('Could not load doctor profile')),
                ),
              ],
            )
          : CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Stretchy (iOS-style overscroll bounce) collapsing header -
                // the photo carousel parallax-scrolls and shrinks behind the
                // app bar, landing on a solid compact bar with the doctor's
                // name once fully collapsed. No FlexibleSpaceBar.title here -
                // the collapsed-bar name is the Positioned overlay below,
                // crossfaded against the carousel's own name via
                // _collapseProgress (see _onScroll's doc comment).
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  backgroundColor: const Color(0xffFDF2FA),
                  elevation: 0,
                  expandedHeight: _kExpandedHeaderHeight,
                  leadingWidth: 60,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: _GlassIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        background: _PhotoCarousel(
                          images: doctor!.galleryImages.isNotEmpty
                              ? doctor!.galleryImages
                              : (doctor!.profileImage.isNotEmpty
                                    ? [doctor!.profileImage]
                                    : []),
                          name: doctor!.displayName,
                          specialization: doctor!.specialization,
                          collapseProgress: _collapseProgress,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 60,
                        right: 16,
                        height: kToolbarHeight,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ValueListenableBuilder<double>(
                            valueListenable: _collapseProgress,
                            builder: (context, progress, child) => Opacity(
                              opacity: progress,
                              child: child,
                            ),
                            child: CustomText(
                              text: doctor!.displayName,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: const Color(0xff530630),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // My Story - leads with the personal, empathetic
                      // narrative (why she coaches, her philosophy) rather
                      // than credentials, so the page reads like getting to
                      // know a person instead of scanning a CV.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CustomText(
                            text: 'My Story',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: const Color(0xff530630),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _ExpandableBio(
                            text: doctor!.bio.isNotEmpty
                                ? doctor!.bio
                                : _placeholderBio,
                            expanded: _bioExpanded,
                            onToggle: () =>
                                setState(() => _bioExpanded = !_bioExpanded),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Pull-quote highlight - a single distilled line of her
                      // philosophy (dieticianProfile.pullQuote, editable from
                      // the dietician app), set apart visually with a soft
                      // glow so it reads as a takeaway rather than more
                      // paragraph text.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Positioned(
                                top: -18,
                                right: -18,
                                child: _GlowBlob(
                                  size: 80,
                                  color: Color(0xffF670CA),
                                ),
                              ),
                              const Positioned(
                                bottom: -16,
                                left: -14,
                                child: _GlowBlob(
                                  size: 56,
                                  color: Color(0xff851653),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xffFEF6FB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xffFCE7F6),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                        text: doctor!.pullQuote.isNotEmpty
                                            ? doctor!.pullQuote
                                            : _placeholderPullQuote,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        color: const Color(0xff851653),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Credentials - kept, but demoted to compact supporting
                      // chips after the story instead of leading with them.
                      // Each chip pops in with its own slight stagger.
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
                                  delay: const Duration(milliseconds: 240),
                                ),
                              if (doctor!.experience > 0) ...[
                                const SizedBox(width: 12),
                                _buildInfoCard(
                                  icon: Icons.work_outline,
                                  label: 'Experience',
                                  value: '${doctor!.experience} yrs',
                                  delay: const Duration(milliseconds: 300),
                                ),
                              ],
                              if (doctor!.qualification.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                _buildInfoCard(
                                  icon: Icons.school_outlined,
                                  label: 'Degree',
                                  value: doctor!.qualification,
                                  delay: const Duration(milliseconds: 360),
                                ),
                              ],
                            ],
                          ),
                        ),

                      const SizedBox(height: 28),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 260),
                        child: SocialMediaSection(
                          youtube: youtubePosts,
                          instagram: instagramPosts,
                        ),
                      ),

                      const SizedBox(height: 28),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 320),
                        child: ReviewsSection(
                          reviews: reviews,
                          averageRating: averageRating,
                          myReview: myReview,
                          doctorName: doctor!.displayName,
                          onSubmit: _submitReview,
                        ),
                      ),

                      const SizedBox(height: 28),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 380),
                        child: ArticlesSection(articles: articles),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Duration delay,
  }) {
    return Expanded(
      child: FadeSlideIn(
        delay: delay,
        offset: 14,
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
      ),
    );
  }
}

/// The circular translucent back button used over the photo header (and,
/// when [dark] is false while loading/erroring, over a plain white
/// background) - a frosted-glass pill rather than a plain Material
/// IconButton so it stays legible over any photo without needing to know
/// the image's own contrast.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xffFCE7F6)
                  : Colors.black.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: Border.all(
                color: dark
                    ? const Color(0xffF3D9E9)
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              icon,
              color: dark ? const Color(0xff851653) : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft, mostly-transparent radial glow - purely decorative depth behind
/// the pull-quote card, not a hard blurred shape (no BackdropFilter cost),
/// just a gradient that fades to nothing.
class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bio paragraph that clamps to 4 lines with a "Read more" toggle once the
/// text is long enough to likely overflow - AnimatedSize smooths the height
/// change instead of the layout jumping straight to full height.
class _ExpandableBio extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableBio({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isLong = text.length > 220;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: CustomText(
            text: text,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: const Color(0xff4D5761),
            height: 1.5,
            maxLines: !isLong || expanded ? null : 4,
            overflow: !isLong || expanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          TapScale(
            onTap: onToggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: expanded ? 'Show less' : 'Read more',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: const Color(0xffF670CA),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Color(0xffF670CA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Skeleton shown while the profile loads - mirrors the real page's shape
/// (photo header, story lines, quote block) instead of a bare spinner, so
/// the wait reads as "content is on its way".
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: _GlassIconButton(
              icon: Icons.arrow_back,
              dark: true,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const ShimmerBox(height: 260, borderRadius: BorderRadius.zero),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 110,
                  height: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 14),
                const ShimmerBox(height: 13, borderRadius: BorderRadius.all(Radius.circular(6))),
                const SizedBox(height: 8),
                const ShimmerBox(height: 13, borderRadius: BorderRadius.all(Radius.circular(6))),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: 200,
                  height: 13,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 22),
                const ShimmerBox(height: 88, borderRadius: BorderRadius.all(Radius.circular(12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed (edge-to-edge, no side padding/rounding) auto-scrolling photo
/// carousel that IS the About Doctor page's collapsing header - lives inside
/// the SliverAppBar's flexibleSpace, so it parallax-scrolls and shrinks away
/// as the page scrolls. Advances every 4s and loops; name/specialization
/// are overlaid at the bottom (gradient + white text) while expanded. Falls
/// back to a plain placeholder (still carrying the name overlay) when there
/// are no photos at all, so identity is never lost even before any are
/// uploaded. The first frame is wrapped in a Hero so tapping the doctor's
/// card on Home morphs its thumbnail straight into this header.
class _PhotoCarousel extends StatefulWidget {
  final List<String> images;
  final String name;
  final String specialization;
  // Shared with the SliverAppBar's compact title (see _onScroll's doc
  // comment on _DoctorDetailViewState) - this overlay fades to (1 -
  // progress) so the two names are always complementary, never both
  // more-than-half visible at once.
  final ValueListenable<double> collapseProgress;

  const _PhotoCarousel({
    required this.images,
    required this.name,
    required this.specialization,
    required this.collapseProgress,
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

  Widget _image(int index) {
    final image = CachedNetworkImage(
      imageUrl: widget.images[index],
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xffFCE7F6),
        child: const Icon(
          Icons.image_outlined,
          size: 48,
          color: Color(0xff9DA4AE),
        ),
      ),
    );
    // Only the first frame carries the shared Hero tag - a PageView can't
    // have more than one widget wearing the same tag on screen at once.
    return index == 0 ? Hero(tag: doctorPhotoHeroTag, child: image) : image;
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
              ? Hero(
                  tag: doctorPhotoHeroTag,
                  child: Container(color: const Color(0xffFCE7F6)),
                )
              : PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) => _image(index),
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
            child: ValueListenableBuilder<double>(
              valueListenable: widget.collapseProgress,
              builder: (context, progress, child) => Opacity(
                opacity: 1 - progress,
                child: child,
              ),
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
          ),

          if (widget.images.length > 1)
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.collapseProgress,
                builder: (context, progress, child) => Opacity(
                  opacity: 1 - progress,
                  child: child,
                ),
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
            ),
        ],
      ),
    );
  }
}
