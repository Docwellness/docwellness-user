import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/modules/home/views/image_viewer.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SavedScreen extends StatelessWidget {
  final List<Map<String, dynamic>> savedQuotes;
  final List<Map<String, dynamic>> savedVideos;

  const SavedScreen({
    super.key,
    required this.savedQuotes,
    required this.savedVideos,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = savedQuotes.isEmpty && savedVideos.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Saved",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Color(0xff1F2A37),
          ),
        ),
      ),
      body: isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Color(0xff9DA4AE),
                  ),
                  const SizedBox(height: 16),
                  CustomText(
                    text: 'No saved items yet',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff6C737F),
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    text: 'Tap the bookmark icon to save quotes & videos',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff9DA4AE),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Saved Quotes ──
                  if (savedQuotes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 16,
                        bottom: 8,
                      ),
                      child: CustomText(
                        text: 'Saved Quotes',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff530630),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 190,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: savedQuotes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final q = savedQuotes[index];
                            final imageUrl = q['imageUrl'] as String? ?? '';
                            final text = q['text'] as String? ?? '';

                            return GestureDetector(
                              onTap: () {
                                if (imageUrl.isNotEmpty) {
                                  Get.to(
                                    () => ImageViewer(
                                      title: 'Quote',
                                      subTitle: text,
                                      image: imageUrl,
                                      isNetwork: true,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Color(0xfffbcdec),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: imageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                height: 130,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => SizedBox(
                                                  height: 130,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Color(
                                                            0xff851653,
                                                          ),
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                                errorWidget: (_, __, ___) =>
                                                    Container(
                                                      height: 130,
                                                      color: Color(0xffFDF2FA),
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Color(
                                                          0xff9DA4AE,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                height: 130,
                                                color: Color(0xffFDF2FA),
                                                child: Icon(
                                                  Icons.format_quote,
                                                  color: Color(0xff9DA4AE),
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (text.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: CustomText(
                                          text: text,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xff530630),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // ── Saved Videos ──
                  if (savedVideos.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 24,
                        bottom: 8,
                      ),
                      child: CustomText(
                        text: 'Saved Videos',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff530630),
                      ),
                    ),
                    ...savedVideos.map((v) {
                      final title = v['title'] as String? ?? 'Video';
                      final text = v['text'] as String? ?? '';
                      final thumbnailUrl = v['thumbnailUrl'] as String? ?? '';
                      final bannerImage = v['bannerImage'] as String? ?? '';
                      final youtubeUrl = v['youtubeUrl'] as String? ?? '';

                      // Prefer thumbnail URL > YouTube auto-thumb > banner
                      String displayImage = '';
                      if (thumbnailUrl.isNotEmpty &&
                          thumbnailUrl.startsWith('http')) {
                        displayImage = thumbnailUrl;
                      } else if (youtubeUrl.isNotEmpty) {
                        final ytId = YoutubePlayer.convertUrlToId(youtubeUrl);
                        if (ytId != null) {
                          displayImage =
                              'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
                        }
                      } else if (bannerImage.isNotEmpty) {
                        displayImage = bannerImage.startsWith('http')
                            ? bannerImage
                            : '${AppConfig.baseUrl}$bannerImage';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (displayImage.isNotEmpty) {
                              Get.to(
                                () => ImageViewer(
                                  title: title,
                                  subTitle: text,
                                  image: displayImage,
                                  isNetwork: true,
                                ),
                              );
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: displayImage.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: displayImage,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 100,
                                          height: 100,
                                          color: Color(0xffFDF2FA),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xff851653),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          width: 100,
                                          height: 100,
                                          color: Color(0xffFDF2FA),
                                          child: Icon(
                                            Icons.videocam,
                                            color: Color(0xff9DA4AE),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Color(0xffFDF2FA),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.videocam,
                                          color: Color(0xff9DA4AE),
                                          size: 36,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: title,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff851653),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (text.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      CustomText(
                                        text: text,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xff4D5761),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    CustomText(
                                      text: v['source'] as String? ?? '',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff9DA4AE),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
