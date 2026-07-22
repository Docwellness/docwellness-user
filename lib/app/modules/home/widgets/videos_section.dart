import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideosSection extends StatefulWidget {
  const VideosSection({super.key});

  @override
  State<VideosSection> createState() => _VideosSectionState();
}

class _VideosSectionState extends State<VideosSection> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final res = await _api.request(
        endPoint: '/videos',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _videos = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
          _loading = false;
        });
        return;
      }
    } catch (e) {
      log('VideosSection fetch error: $e');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _getThumbnail(Map<String, dynamic> video) {
    final thumb = video['thumbnailUrl'] as String? ?? '';
    if (thumb.isNotEmpty && thumb.startsWith('http')) return thumb;
    // Generate YouTube thumbnail if available
    final youtubeUrl = video['youtubeUrl'] as String? ?? '';
    if (youtubeUrl.isNotEmpty) {
      final ytId = _extractYoutubeId(youtubeUrl);
      if (ytId != null) return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    }
    final banner = video['bannerImage'] as String? ?? '';
    if (banner.isNotEmpty) return '${AppConfig.baseUrl}$banner';
    return thumb;
  }

  String? _extractYoutubeId(String url) {
    final patterns = [
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?.*v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // If loading or no videos, show nothing or loader
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(10),
            color: Color(0xffFEF6FB),
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xff851653)),
            ),
          ),
        ],
      );
    }

    if (_videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Color(0xffFEF6FB)),
          child: SizedBox(
            height: 433,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final video = _videos[index];
                final thumbUrl = _getThumbnail(video);
                final title = (video['title'] as String?) ?? '';
                final isYoutube = video['source'] == 'YouTube';
                final youtubeUrl = video['youtubeUrl'] as String? ?? '';
                final isShort = youtubeUrl.contains('/shorts/');

                return GestureDetector(
                  onTap: () {
                    if (isYoutube) {
                      final ytId = _extractYoutubeId(youtubeUrl);
                      if (ytId != null) {
                        if (isShort) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) =>
                                  _ShortsPlayer(videoId: ytId, title: title),
                            ),
                          );
                        } else {
                          final desc = (video['text'] as String?) ?? '';
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _PatientYoutubePlayer(
                                videoId: ytId,
                                title: title,
                                description: desc,
                                thumbnailUrl: thumbUrl.isNotEmpty
                                    ? thumbUrl
                                    : null,
                                isShort: false,
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Container(
                    width: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black12,
                    ),
                    child: Stack(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: thumbUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: thumbUrl,
                                  width: 240,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xff851653),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Color(0xff9DA4AE),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.videocam_outlined,
                                    size: 48,
                                    color: Color(0xff9DA4AE),
                                  ),
                                ),
                        ),
                        // Gradient overlay
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Play button
                        if (isYoutube)
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        // Title
                        if (title.isNotEmpty)
                          Positioned(
                            left: 16,
                            bottom: 18,
                            right: 16,
                            child: CustomText(
                              text: title,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              maxLines: 2,
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
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CustomText(
            text: "Videos for you",
            fontWeight: FontWeight.w400,
            color: Color(0xff9F1561),
            fontSize: 17,
          ),
          SizedBox(width: 7),
          const Icon(Icons.arrow_forward, color: Color(0xff530630), size: 18),
        ],
      ),
    );
  }
}

/// Video detail screen — shows thumbnail + play overlay, plays YouTube on tap
class _PatientYoutubePlayer extends StatelessWidget {
  final String videoId;
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final bool isShort;

  const _PatientYoutubePlayer({
    required this.videoId,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.isShort = false,
  });

  String get _thumb =>
      thumbnailUrl ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  void _openPlayer(BuildContext context) {
    if (isShort) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _ShortsPlayer(videoId: videoId, title: title),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              _FullScreenYoutubePlayer(videoId: videoId, title: title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
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
                onTap: () => _openPlayer(context),
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

/// Full-length YouTube player — auto-rotates landscape, with ±10s seek
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
    // Auto-rotate to landscape for full-length videos
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: false,
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
    // Restore all orientations when leaving
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller.dispose();
    super.dispose();
  }

  void _seek(int seconds) {
    final current = _controller.value.position;
    final target = current + Duration(seconds: seconds);
    _controller.seekTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
        ]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xff851653),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xff851653),
          handleColor: Color(0xff851653),
        ),
        bottomActions: [
          const SizedBox(width: 8),
          // -10s
          IconButton(
            icon: const Icon(Icons.replay_10, color: Colors.white, size: 24),
            onPressed: () => _seek(-10),
            padding: EdgeInsets.zero,
          ),
          CurrentPosition(),
          const SizedBox(width: 4),
          ProgressBar(isExpanded: true),
          const SizedBox(width: 4),
          RemainingDuration(),
          // +10s
          IconButton(
            icon: const Icon(Icons.forward_10, color: Colors.white, size: 24),
            onPressed: () => _seek(10),
            padding: EdgeInsets.zero,
          ),
          PlaybackSpeedButton(),
          FullScreenButton(),
          const SizedBox(width: 8),
        ],
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

/// Instagram Reels-style vertical player for YouTube Shorts
class _ShortsPlayer extends StatefulWidget {
  final String videoId;
  final String? title;

  const _ShortsPlayer({required this.videoId, this.title});

  @override
  State<_ShortsPlayer> createState() => _ShortsPlayerState();
}

class _ShortsPlayerState extends State<_ShortsPlayer> {
  late YoutubePlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Lock to portrait for Shorts
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        enableCaption: false,
        hideControls: true, // We draw our own overlay
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  void _seek(int seconds) {
    final current = _controller.value.position;
    _controller.seekTo(current + Duration(seconds: seconds));
  }

  void _togglePlay() {
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
    setState(() {});
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: false,
          progressColors: const ProgressBarColors(
            playedColor: Color(0xff851653),
            handleColor: Color(0xff851653),
          ),
        ),
        builder: (context, player) {
          return GestureDetector(
            onTap: _toggleControls,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  // Video fills screen
                  SizedBox(
                    width: size.width,
                    height: size.height,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: size.width,
                        height: size.width * (16 / 9),
                        child: player,
                      ),
                    ),
                  ),

                  // Dark gradient top + bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.45),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0, 0.2, 0.7, 1],
                        ),
                      ),
                    ),
                  ),

                  // Top bar — back + title
                  if (_showControls)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Text(
                                  widget.title ?? 'Short',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Centre play/pause
                  if (_showControls)
                    Positioned.fill(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // -10s
                            GestureDetector(
                              onTap: () => _seek(-10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.replay_10,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            // Play / Pause
                            ValueListenableBuilder<YoutubePlayerValue>(
                              valueListenable: _controller,
                              builder: (_, val, __) => GestureDetector(
                                onTap: _togglePlay,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    val.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            // +10s
                            GestureDetector(
                              onTap: () => _seek(10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.forward_10,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bottom progress bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: ValueListenableBuilder<YoutubePlayerValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) {
                          final total = value.metaData.duration.inMilliseconds
                              .toDouble();
                          final pos = value.position.inMilliseconds.toDouble();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2.5,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 10,
                                  ),
                                  activeTrackColor: const Color(0xff851653),
                                  inactiveTrackColor: Colors.white30,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: total > 0 ? pos.clamp(0, total) : 0,
                                  min: 0,
                                  max: total > 0 ? total : 1,
                                  onChanged: (v) => _controller.seekTo(
                                    Duration(milliseconds: v.toInt()),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
