import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/social_media_post_model.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/functions/link_launcher.dart';
import 'package:flutter/material.dart';

/// "Follow along" section on the About Doctor page - YouTube clips scroll
/// horizontally (the natural shape for short-form video thumbnails),
/// Instagram posts stack as tall vertical cards (closer to how they read
/// on Instagram itself). Both just open the real post/video in an in-app
/// WebView on tap (see openWebLink) rather than re-implementing a player -
/// this section is "come see my socials", not a video library.
class SocialMediaSection extends StatelessWidget {
  final List<SocialMediaPostModel> youtube;
  final List<SocialMediaPostModel> instagram;

  const SocialMediaSection({
    super.key,
    required this.youtube,
    required this.instagram,
  });

  @override
  Widget build(BuildContext context) {
    if (youtube.isEmpty && instagram.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomText(
            text: 'Follow Along',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xff530630),
          ),
        ),
        const SizedBox(height: 14),
        if (youtube.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.smart_display, size: 16, color: Color(0xff851653)),
                const SizedBox(width: 6),
                CustomText(
                  text: 'On YouTube',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xff851653),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: youtube.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _YoutubeCard(post: youtube[index]),
            ),
          ),
          const SizedBox(height: 22),
        ],
        if (instagram.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xff851653)),
                const SizedBox(width: 6),
                CustomText(
                  text: 'On Instagram',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xff851653),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: instagram
                  .map((post) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _InstagramCard(post: post),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _YoutubeCard extends StatelessWidget {
  final SocialMediaPostModel post;
  const _YoutubeCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openWebLink(url: post.url, title: 'YouTube'),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              post.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: post.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xffFEF6FB),
                        child: const Icon(Icons.smart_display, color: Color(0xff9DA4AE)),
                      ),
                    )
                  : Container(color: const Color(0xffFEF6FB)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
              ),
              if (post.caption.isNotEmpty)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: CustomText(
                    text: post.caption,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.white,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstagramCard extends StatelessWidget {
  final SocialMediaPostModel post;
  const _InstagramCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openWebLink(url: post.url, title: 'Instagram'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: cardBorder,
          boxShadow: cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: post.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: post.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xffFEF6FB),
                        child: const Icon(Icons.image_outlined, color: Color(0xff9DA4AE)),
                      ),
                    )
                  : Container(color: const Color(0xffFEF6FB)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.caption.isNotEmpty)
                    CustomText(
                      text: post.caption,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: const Color(0xff4D5761),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xffF670CA)),
                      const SizedBox(width: 4),
                      CustomText(
                        text: 'View on Instagram',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xffF670CA),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
