import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/modules/home/views/image_viewer.dart';
import 'package:docwellness/app/modules/home/views/saved_screen.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MotivationScreen extends StatefulWidget {
  const MotivationScreen({super.key});

  @override
  State<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends State<MotivationScreen> {
  List<Map<String, dynamic>> quotes = [];
  List<Map<String, dynamic>> videos = [];
  bool isLoading = true;
  final Set<String> savedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.patientApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final results = await Future.wait([
        dio.get('/quotes', options: Options(headers: headers)),
        dio.get('/videos', options: Options(headers: headers)),
      ]);

      if (results[0].statusCode == 200 && results[0].data['success'] == true) {
        quotes = List<Map<String, dynamic>>.from(results[0].data['data'] ?? []);
      }
      if (results[1].statusCode == 200 && results[1].data['success'] == true) {
        videos = List<Map<String, dynamic>>.from(results[1].data['data'] ?? []);
        log('Videos data: $videos');
      }
    } catch (e) {
      log('MotivationScreen fetch error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _toggleSave(String id) {
    setState(() {
      if (savedIds.contains(id)) {
        savedIds.remove(id);
      } else {
        savedIds.add(id);
      }
    });
  }

  String? _extractYoutubeVideoId(String url) {
    final patterns = [
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?.*v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
          "Motivation",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Color(0xff1F2A37),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final savedQuotes = quotes
                  .where((q) => savedIds.contains(q['_id'] as String? ?? ''))
                  .toList();
              final savedVideos = videos
                  .where((v) => savedIds.contains(v['_id'] as String? ?? ''))
                  .toList();
              Get.to(
                () => SavedScreen(
                  savedQuotes: savedQuotes,
                  savedVideos: savedVideos,
                ),
              );
            },
            icon: Icon(Icons.bookmark, color: const Color(0xffDE2493)),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xff851653)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── QUOTES — horizontal scroll ──
                  if (quotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: quotes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final q = quotes[index];
                            final imageUrl = q['imageUrl'] as String? ?? '';
                            final text = q['text'] as String? ?? '';
                            final id = q['_id'] as String? ?? '';
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // image
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
                                    // text + bookmark
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        right: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CustomText(
                                                  text: text.isNotEmpty
                                                      ? text
                                                      : 'Quote #${index + 1}',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xff530630),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () => _toggleSave(id),
                                              icon: Icon(
                                                savedIds.contains(id)
                                                    ? Icons.bookmark
                                                    : Icons
                                                          .bookmark_border_outlined,
                                                color: Color(0xffDE2493),
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ],
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

                  const SizedBox(height: 25),

                  // ── VIDEOS — vertical list ──
                  if (videos.isNotEmpty)
                    Container(
                      color: Color(0xffFEF7FF),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10,
                          bottom: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: "Videos",
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff4D5761),
                            ),
                            const SizedBox(height: 6),
                            ...videos.asMap().entries.map((entry) {
                              final v = entry.value;
                              final title = v['title'] as String? ?? 'Video';
                              final text = v['text'] as String? ?? '';
                              final thumbnailUrl =
                                  v['thumbnailUrl'] as String? ?? '';
                              final bannerImage =
                                  v['bannerImage'] as String? ?? '';
                              final youtubeUrl =
                                  v['youtubeUrl'] as String? ?? '';
                              final id = v['_id'] as String? ?? '';

                              // pick best image: thumbnail > youtube auto-thumb > banner
                              String displayImage = '';
                              if (thumbnailUrl.isNotEmpty &&
                                  thumbnailUrl.startsWith('http')) {
                                displayImage = thumbnailUrl;
                              } else if (youtubeUrl.isNotEmpty) {
                                final ytId = _extractYoutubeVideoId(youtubeUrl);
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
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    final source = v['source'] as String? ?? '';
                                    if (source == 'YouTube' &&
                                        youtubeUrl.isNotEmpty) {
                                      final ytId = _extractYoutubeVideoId(
                                        youtubeUrl,
                                      );
                                      if (ytId != null) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                _MotivationYoutubePlayer(
                                                  videoId: ytId,
                                                  title: title,
                                                  description: text,
                                                  thumbnailUrl:
                                                      displayImage.isNotEmpty
                                                      ? displayImage
                                                      : null,
                                                ),
                                          ),
                                        );
                                        return;
                                      }
                                    }
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // thumbnail with play overlay
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: displayImage.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: displayImage,
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) =>
                                                        Container(
                                                          width: 120,
                                                          height: 120,
                                                          color: Color(
                                                            0xffFDF2FA,
                                                          ),
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color: Color(
                                                                    0xff851653,
                                                                  ),
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                        ),
                                                    errorWidget: (_, __, ___) =>
                                                        Container(
                                                          width: 120,
                                                          height: 120,
                                                          color: Color(
                                                            0xffFDF2FA,
                                                          ),
                                                          child: Icon(
                                                            Icons.videocam,
                                                            color: Color(
                                                              0xff9DA4AE,
                                                            ),
                                                          ),
                                                        ),
                                                  )
                                                : Container(
                                                    width: 120,
                                                    height: 120,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xffFDF2FA),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.videocam,
                                                      color: Color(0xff9DA4AE),
                                                      size: 40,
                                                    ),
                                                  ),
                                          ),
                                          // Play icon overlay
                                          Positioned.fill(
                                            child: Center(
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      // info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              text: title,
                                              fontSize: 18,
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
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                CustomText(
                                                  text:
                                                      v['source'] as String? ??
                                                      '',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xff4D5761),
                                                ),
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 32,
                                                      height: 32,
                                                      child: IconButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () =>
                                                            _toggleSave(id),
                                                        icon: Icon(
                                                          savedIds.contains(id)
                                                              ? Icons.bookmark
                                                              : Icons
                                                                    .bookmark_border_outlined,
                                                          color: Color(
                                                            0xffDE2493,
                                                          ),
                                                          size: 22,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.arrow_right_sharp,
                                                      color: Color(0xff530630),
                                                      size: 32,
                                                    ),
                                                  ],
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
                            }),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

/// Video detail screen — shows thumbnail + play overlay, plays YouTube on tap
class _MotivationYoutubePlayer extends StatelessWidget {
  final String videoId;
  final String? title;
  final String? description;
  final String? thumbnailUrl;

  const _MotivationYoutubePlayer({
    required this.videoId,
    this.title,
    this.description,
    this.thumbnailUrl,
  });

  String get _thumb =>
      thumbnailUrl ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'Workout Video',
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              if (title != null && title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CustomText(
                    text: title!,
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                    color: Color(0xff851653),
                  ),
                ),
              // Thumbnail with play button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _FullScreenYoutubePlayer(
                        videoId: videoId,
                        title: title,
                      ),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _thumb,
                        height: 340,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 340,
                          color: const Color(0xffFDF2FA),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xff851653),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 340,
                          color: const Color(0xffFDF2FA),
                          child: const Icon(
                            Icons.videocam,
                            color: Color(0xff9DA4AE),
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (description != null && description!.isNotEmpty)
                CustomText(
                  text: description!,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: Color(0xff49454F),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Separate full-screen YouTube player screen
class _FullScreenYoutubePlayer extends StatefulWidget {
  final String videoId;
  final String? title;

  const _FullScreenYoutubePlayer({required this.videoId, this.title});

  @override
  State<_FullScreenYoutubePlayer> createState() =>
      _FullScreenYoutubePlayerState();
}

class _FullScreenYoutubePlayerState extends State<_FullScreenYoutubePlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xff851653),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xff851653),
          handleColor: Color(0xff851653),
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              widget.title ?? 'Video',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          body: Center(child: player),
        );
      },
    );
  }
}
