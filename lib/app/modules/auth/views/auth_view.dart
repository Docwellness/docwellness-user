import 'package:docwellness/app/modules/auth/views/login_view.dart';
import 'package:docwellness/app/modules/auth/views/sign_up_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/legal_text_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:get/get.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final GlobalKey<_OnboardingVideoState> _videoKey =
      GlobalKey<_OnboardingVideoState>();

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => showLegalTextPage('Terms of Service', termsOfServiceText);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => showLegalTextPage('Privacy Policy', privacyPolicyText);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  // Stops/releases the video before navigating away (so it - and any audio -
  // don't keep running invisibly underneath the Login/Sign-up screen), then
  // starts it fresh from the beginning once the user comes back.
  Future<void> _navigateAndReplayVideo(Widget Function() pageBuilder) async {
    await _videoKey.currentState?.pauseAndRelease();
    await Get.to(pageBuilder);
    _videoKey.currentState?.relaunch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFEF6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Column(
            children: [
              // Scrollable so short screens never overflow, but this is the
              // ONLY part that scrolls - the buttons/terms below are outside
              // it, so they always stay pinned to the bottom of the screen.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 55),
                      // Stacked lockup (icon above wordmark/tagline) - same
                      // asset as the splash screen, for a consistent brand
                      // mark between the two back-to-back launch screens.
                      Image.asset(
                        'assets/icons/logo.png',
                        height: 170,
                        filterQuality: FilterQuality.high,
                      ),
                      SizedBox(height: 32),
                      _OnboardingVideo(key: _videoKey),
                      SizedBox(height: 28),
                      CustomText(
                        text: 'Welcome to Docwellness!',
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: Color(0xff851653),
                      ),

                      SizedBox(height: 13),
                      CustomText(
                        text:
                            'Your all-in-one wellness companion — personalized nutrition, expert guidance, and daily motivation, wherever you are. Nourishing you, transforming your life.',
                        fontWeight: FontWeight.w400,
                        fontSize: 11.5,
                        color: Color(0xff4D5761),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              CustomButton(
                fontSize: 14,
                onTap: () => _navigateAndReplayVideo(() => LoginScreen()),
                text: "Log in",
                isOutline: false,
              ),
              SizedBox(height: 20),
              CustomButton(
                fontSize: 14,
                onTap: () =>
                    _navigateAndReplayVideo(() => SignUpView()),
                text: "I’m new, Sign me up",
                isOutline: true,
              ),
              SizedBox(height: 19),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w400,
                    fontSize: 11.5,
                    color: const Color(0xff6C737F),
                  ),
                  children: [
                    const TextSpan(
                      text: 'By logging on or registering, you agree to our ',
                    ),
                    TextSpan(
                      text: 'terms and conditions',
                      recognizer: _termsTap,
                      style: const TextStyle(
                        color: Color(0xff851653),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'privacy policy',
                      recognizer: _privacyTap,
                      style: const TextStyle(
                        color: Color(0xff851653),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Silent, looping, autoplaying intro video - replaces the old image
/// carousel. Aspect ratio comes from the video itself (once initialized) so
/// the original resolution is preserved without cropping; a soft placeholder
/// is shown at the carousel's old fixed height while the video loads or
/// between release/relaunch.
class _OnboardingVideo extends StatefulWidget {
  const _OnboardingVideo({super.key});

  @override
  State<_OnboardingVideo> createState() => _OnboardingVideoState();
}

class _OnboardingVideoState extends State<_OnboardingVideo> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _startVideo();
  }

  void _startVideo() {
    final controller = VideoPlayerController.asset(
      'assets/videos/onboarding_intro.mp4',
    );
    _controller = controller;
    // setLooping/setVolume are no-ops until the controller reports
    // isInitialized (VideoPlayerController._applyVolume/_applyLooping both
    // early-return on an uninitialized controller), so they must be set only
    // after the initialize() future completes.
    controller.initialize().then((_) async {
      // Guard against a stale callback firing after pauseAndRelease()
      // replaced/cleared _controller, or the widget having been unmounted.
      if (!mounted || _controller != controller) return;
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted || _controller != controller) return;
      setState(() {
        _isInitialized = true;
        _isMuted = true;
      });
      controller.play();
    });
  }

  /// Stops playback and fully releases the video's decode/audio resources -
  /// call right before navigating away.
  Future<void> pauseAndRelease() async {
    final controller = _controller;
    _controller = null;
    if (mounted) {
      setState(() => _isInitialized = false);
    }
    await controller?.pause();
    await controller?.dispose();
  }

  /// Creates a fresh controller and starts the video over from the
  /// beginning, muted - call when navigating back to this screen.
  void relaunch() {
    if (!mounted || _controller != null) return;
    _startVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;
    final unmuting = _isMuted;
    setState(() => _isMuted = !_isMuted);
    await controller.setVolume(_isMuted ? 0 : 1);
    if (unmuting) {
      // Browsers are stricter about honoring audio on an element that is
      // already autoplaying muted than about a fresh play() call made
      // directly inside a user-gesture handler - re-issuing play() here
      // (harmless no-op on position, see VideoPlayerController.play()) makes
      // the unmute reliably "stick" instead of silently staying muted.
      await controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: (_isInitialized && controller != null)
          ? Stack(
              alignment: Alignment.bottomRight,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              height: 209,
              width: double.infinity,
              color: const Color(0xffFCE7F6),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Color(0xff851653),
                strokeWidth: 2,
              ),
            ),
    );
  }
}
