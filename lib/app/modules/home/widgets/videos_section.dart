import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/modules/home/controllers/videos_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ── Card geometry ────────────────────────────────────────────────────────────
// Portrait 9:16-ish story cards, like the reference "Stories entdecken" rail.
const double _kCardW = 150;
const double _kCardH = 244;
const double _kGap = 12;
const double _kRadius = 16;
const double _kRailPad = 16; // matches the rest of Home's horizontal padding
const double _kCardExtent = _kCardW + _kGap;

const Color _kBrandPink = Color(0xff9F1561);
const Color _kBrandPlum = Color(0xff851653);
const Color _kBrandTint = Color(0xffFEF6FB);

// ── Shared helpers (used by the rail, the overlay and the "See all" grid) ─────
String? youtubeId(String url) {
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

/// Best available still for a video. Prefers an explicit [thumbnailUrl]
/// (the prod seed sets this to YouTube's original-aspect-ratio Shorts frame
/// `.../oardefault.jpg` — no 4:3 letterboxing), then a derived YouTube
/// thumbnail, then an uploaded banner.
String videoThumb(Map<String, dynamic> video) {
  final thumb = (video['thumbnailUrl'] as String?)?.trim() ?? '';
  if (thumb.startsWith('http')) return thumb;
  final ytUrl = (video['youtubeUrl'] as String?) ?? '';
  final id = ytUrl.isNotEmpty ? youtubeId(ytUrl) : null;
  if (id != null) return 'https://i.ytimg.com/vi/$id/oardefault.jpg';
  final banner = (video['bannerImage'] as String?) ?? '';
  if (banner.isNotEmpty) return '${AppConfig.baseUrl}$banner';
  return thumb;
}

bool isShortUrl(String url) => url.contains('/shorts/');

void openVideo(BuildContext context, Map<String, dynamic> video) {
  final ytUrl = (video['youtubeUrl'] as String?) ?? '';
  final id = youtubeId(ytUrl);
  if ((video['source'] != 'YouTube') || id == null) return;
  final title = (video['title'] as String?) ?? '';
  if (isShortUrl(ytUrl)) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ShortsPlayer(videoId: id, title: title),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PatientYoutubePlayer(
          videoId: id,
          title: title,
          description: (video['text'] as String?) ?? '',
          thumbnailUrl: videoThumb(video),
          isShort: false,
        ),
      ),
    );
  }
}

// ── Section ──────────────────────────────────────────────────────────────────
class VideosSection extends StatelessWidget {
  const VideosSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VideosController>()
        ? Get.find<VideosController>()
        : Get.put(VideosController(), permanent: true);

    // Obx on the whole section so a Home pull-to-refresh flips cleanly
    // between the loading / empty / populated branches.
    return Obx(() {
      if (controller.isLoading.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onTap: null),
            const SizedBox(height: 12),
            const SizedBox(
              height: _kCardH,
              child: Center(
                child: CircularProgressIndicator(color: _kBrandPlum),
              ),
            ),
          ],
        );
      }

      final videos = controller.videos;
      if (videos.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _AllVideosScreen(videos: videos)),
            ),
          ),
          const SizedBox(height: 12),
          _VideoRail(videos: videos),
        ],
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kRailPad),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const CustomText(
                text: 'Videos for you',
                fontWeight: FontWeight.w500,
                color: _kBrandPink,
                fontSize: 17,
              ),
              const SizedBox(width: 6),
              if (onTap != null)
                const Icon(Icons.arrow_forward, color: _kBrandPlum, size: 18),
              const Spacer(),
              if (onTap != null)
                const CustomText(
                  text: 'See all',
                  fontWeight: FontWeight.w400,
                  color: _kBrandPlum,
                  fontSize: 13,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Rail: horizontal cards + a single inline muted preview on the card in
// focus. Scroll sideways and the preview follows to the next card; scroll the
// section off screen and it stops. ──────────────────────────────────────────
class _VideoRail extends StatefulWidget {
  const _VideoRail({required this.videos});
  final List<Map<String, dynamic>> videos;

  @override
  State<_VideoRail> createState() => _VideoRailState();
}

class _VideoRailState extends State<_VideoRail> with WidgetsBindingObserver {
  final ScrollController _sc = ScrollController();
  YoutubePlayerController? _yt;

  int _focused = 0;
  bool _visible = false; // section visible enough to actively play
  bool _muted = true;
  bool _reduceMotion = false;
  bool _playerReady = false;
  bool _disposed = false;
  Timer? _loadDebounce;

  /// Every call into [_yt] goes through here. youtube_player_flutter talks to
  /// its webview over a platform channel that throws
  /// (MissingPluginException / "used after disposed") if the widget has been
  /// torn down - which happens on a fast navigate-away / re-open. The player
  /// widget itself stays mounted for this rail's whole life (see build), so
  /// this is really just belt-and-braces for the dispose race.
  void _player(void Function(YoutubePlayerController yt) action) {
    final yt = _yt;
    if (yt == null || _disposed || !mounted) return;
    try {
      action(yt);
    } catch (e) {
      log('VideosSection player call skipped: $e');
    }
  }

  List<Map<String, dynamic>> get _videos => widget.videos;

  String? _idAt(int i) {
    if (i < 0 || i >= _videos.length) return null;
    return youtubeId((_videos[i]['youtubeUrl'] as String?) ?? '');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sc.addListener(_onScroll);
    final firstId = _idAt(0);
    if (firstId != null) {
      _yt = YoutubePlayerController(
        initialVideoId: firstId,
        flags: const YoutubePlayerFlags(
          // Start buffering/playing the first card the moment the webview
          // boots, instead of the slower boot -> ready -> load -> buffer
          // chain. It's muted and we pause() immediately if the section
          // isn't actually on screen yet.
          autoPlay: true,
          mute: true,
          loop: true,
          hideControls: true,
          hideThumbnail: true, // our own still sits behind it
          disableDragSeek: true,
          enableCaption: false,
          controlsVisibleAtStart: false,
        ),
      )..addListener(_onPlayerValue);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _loadDebounce?.cancel();
    _sc.removeListener(_onScroll);
    _sc.dispose();
    _yt?.removeListener(_onPlayerValue);
    _yt?.dispose();
    super.dispose();
  }

  // The webview drops load()/play() calls made before it reports ready, so
  // wait for the first ready tick and then start the focused card.
  void _onPlayerValue() {
    if (_playerReady || _disposed || _yt?.value.isReady != true) return;
    _playerReady = true;
    _syncPreview();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _player((yt) => yt.pause());
    } else if (_visible) {
      _syncPreview();
    }
  }

  void _onScroll() {
    if (!_sc.hasClients) return;
    final next = (_sc.offset / _kCardExtent)
        .round()
        .clamp(0, _videos.length - 1);
    if (next != _focused) {
      setState(() => _focused = next);
      // Don't reload the webview for every card the fling passes over -
      // that just aborts each buffer. Load once the scroll stops moving.
      _loadDebounce?.cancel();
      _loadDebounce = Timer(const Duration(milliseconds: 220), _syncPreview);
    }
  }

  void _onScrollEnd() {
    if (!_sc.hasClients) return;
    _loadDebounce?.cancel();
    final target = (_focused * _kCardExtent).clamp(
      _sc.position.minScrollExtent,
      _sc.position.maxScrollExtent,
    );
    if ((target - _sc.offset).abs() > 0.5) {
      _sc.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    _syncPreview();
  }

  void _onVisibility(VisibilityInfo info) {
    // The webview stays mounted for the rail's whole life (build), so this
    // only decides whether to actively play - covered by another route or
    // scrolled well off screen pauses it.
    final vis = info.visibleFraction > 0.5;
    if (vis == _visible) return;
    _visible = vis;
    _syncPreview();
  }

  /// Load + play the focused card's video, or pause when we shouldn't be
  /// playing anything.
  void _syncPreview() {
    if (_disposed || !mounted) return;
    final id = _idAt(_focused);
    if (_reduceMotion || !_visible || id == null) {
      _player((yt) => yt.pause());
      return;
    }
    _player((yt) {
      if (!yt.value.isReady) return; // _onPlayerValue will retry
      if (yt.metadata.videoId != id) {
        yt.load(id);
      } else {
        yt.play();
      }
      _muted ? yt.mute() : yt.unMute();
    });
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _player((yt) => _muted ? yt.mute() : yt.unMute());
  }

  void _openFocused() {
    _player((yt) => yt.pause());
    if (_focused >= 0 && _focused < _videos.length) {
      final v = _videos[_focused];
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _ShortsPlayer(
            videoId: _idAt(_focused)!,
            title: (v['title'] as String?) ?? '',
          ),
        ),
      ).then((_) {
        if (mounted) _syncPreview();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    // Keep the player mounted for the rail's whole life once created - never
    // tear the webview down and rebuild it (that's what threw
    // MissingPluginException / "used after disposed" on fast re-open).
    final canPreview = _yt != null && !_reduceMotion;

    return VisibilityDetector(
      key: const Key('home-videos-rail'),
      onVisibilityChanged: _onVisibility,
      child: SizedBox(
        height: _kCardH,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollEndNotification) _onScrollEnd();
            return false;
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ListView.builder(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: _kRailPad),
                itemCount: _videos.length,
                itemBuilder: (context, i) => _StillCard(
                  video: _videos[i],
                  focused: i == _focused,
                  reduceMotion: _reduceMotion,
                  onTap: () {
                    if (i == _focused) {
                      _openFocused();
                    } else {
                      _sc.animateTo(
                        (i * _kCardExtent).clamp(
                          _sc.position.minScrollExtent,
                          _sc.position.maxScrollExtent,
                        ),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ),
              if (canPreview)
                AnimatedBuilder(
                  animation: Listenable.merge([_sc, _yt!]),
                  builder: (context, _) {
                    final dx = _sc.hasClients
                        ? _kRailPad + _focused * _kCardExtent - _sc.offset
                        : _kRailPad.toDouble();
                    // Keep our own still visible until the video is actually
                    // playing - no black webview, no buffering spinner.
                    final playing = _yt!.value.isPlaying;
                    // Fade the live preview out while the rail is mid-scroll
                    // and back in once the focused card settles into place -
                    // masks the hand-off between one card and the next.
                    final settle =
                        (1 - ((dx - _kRailPad).abs() / 44)).clamp(0.0, 1.0);
                    return Positioned.fill(
                      child: Opacity(
                        opacity: settle,
                        child: Align(
                        alignment: Alignment.topLeft,
                        child: Transform.translate(
                          offset: Offset(dx, 0),
                          child: _PreviewOverlay(
                            video: _videos[_focused],
                            player: YoutubePlayer(
                              controller: _yt!,
                              aspectRatio: 9 / 16,
                              showVideoProgressIndicator: false,
                            ),
                            playing: playing,
                            muted: _muted,
                            onToggleMute: _toggleMute,
                            onTap: _openFocused,
                          ),
                        ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// A resting card: still image only. The focused one is drawn at full size /
// opacity so the eye lands on it (and the live preview sits exactly on top).
class _StillCard extends StatelessWidget {
  const _StillCard({
    required this.video,
    required this.focused,
    required this.reduceMotion,
    required this.onTap,
  });

  final Map<String, dynamic> video;
  final bool focused;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (video['title'] as String?) ?? '';
    final scale = focused || reduceMotion ? 1.0 : 0.94;
    final opacity = focused || reduceMotion ? 1.0 : 0.7;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: Container(
              width: _kCardW,
              height: _kCardH,
              margin: const EdgeInsets.only(right: _kGap),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kRadius),
                color: _kBrandTint,
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: _CardFace(
                thumbUrl: videoThumb(video),
                title: title,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The visual surface shared by a still card and the live-preview overlay:
// full-bleed image, bottom scrim, play glyph + optional one-line title.
class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.thumbUrl,
    required this.title,
    this.overlay,
    this.trailing,
    this.showStill = true,
  });

  final String thumbUrl;
  final String title;

  /// Live player, drawn *below* the still image (the still fades away to
  /// reveal it once playback actually starts — see [showStill]).
  final Widget? overlay;

  /// Bottom-right control (mute toggle) — preview only.
  final Widget? trailing;

  /// Whether the still image covers the player. Kept true until the video is
  /// really playing so the viewer never sees a black webview or a spinner
  /// (opacity on an Android platform view is unreliable, so we cover it with
  /// a plain Flutter image instead of fading the webview itself).
  final bool showStill;

  Widget _still() {
    if (thumbUrl.isEmpty) {
      return const ColoredBox(
        color: _kBrandTint,
        child: Icon(Icons.videocam_outlined,
            size: 40, color: Color(0xff9DA4AE)),
      );
    }
    return CachedNetworkImage(
      imageUrl: thumbUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => const ColoredBox(color: _kBrandTint),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: _kBrandTint,
        child: Icon(Icons.videocam_outlined,
            size: 40, color: Color(0xff9DA4AE)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (overlay != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _kCardW,
                height: _kCardW * 16 / 9,
                child: overlay,
              ),
            ),
          AnimatedOpacity(
            opacity: showStill ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: _still(),
          ),
          // Bottom scrim for legibility.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB3000000)],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0x33FFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 6),
                if (title.isNotEmpty)
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Positioned(right: 8, bottom: 8, child: trailing!),
        ],
      ),
    );
  }
}

class _PreviewOverlay extends StatelessWidget {
  const _PreviewOverlay({
    required this.video,
    required this.player,
    required this.playing,
    required this.muted,
    required this.onToggleMute,
    required this.onTap,
  });

  final Map<String, dynamic> video;
  final Widget player;
  final bool playing;
  final bool muted;
  final VoidCallback onToggleMute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: _kCardW,
        height: _kCardH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _CardFace(
          thumbUrl: videoThumb(video),
          title: (video['title'] as String?) ?? '',
          overlay: IgnorePointer(child: player),
          showStill: !playing,
          trailing: GestureDetector(
            onTap: onToggleMute,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                shape: BoxShape.circle,
              ),
              child: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── "See all" grid ───────────────────────────────────────────────────────────
class _AllVideosScreen extends StatelessWidget {
  const _AllVideosScreen({required this.videos});
  final List<Map<String, dynamic>> videos;

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
        title: const CustomText(
          text: 'Videos for you',
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: _kCardW / _kCardH,
        ),
        itemCount: videos.length,
        itemBuilder: (context, i) {
          final v = videos[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openVideo(context, v),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kRadius),
                color: _kBrandTint,
              ),
              child: _CardFace(
                thumbUrl: videoThumb(v),
                title: (v['title'] as String?) ?? '',
              ),
            ),
          );
        },
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
                        color: Colors.black.withValues(alpha: 0.6),
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
          aspectRatio: 9 / 16,
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
                  // Show the whole 9:16 frame - phones taller than 16:9 would
                  // otherwise crop the Short's baked-in captions off the
                  // sides. Letterboxed against the black scaffold.
                  Positioned.fill(child: Center(child: player)),

                  // Dark gradient top + bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
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
                                  color: Colors.black.withValues(alpha: 0.4),
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
                                    color: Colors.black.withValues(alpha: 0.5),
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
                                  color: Colors.black.withValues(alpha: 0.4),
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
