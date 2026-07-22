import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/forgot_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // permanent: true - this controller's state (and the rest of the auth
  // flow built on top of it) must survive route churn like Get.offAll, not
  // just Get.to pushes. See AuthController.login()'s "account incomplete"
  // branch, which clears the whole nav stack on the way to PersonalInfoView.
  final AuthController controller = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  static const _primary = Color(0xff530630);
  static const _accent = Color(0xff851653);
  static const _bgLight = Color(0xffFDF2FA);

  // Matches the native keyboard show/hide timing so the header collapse
  // reads as one continuous motion instead of trailing or racing it.
  static const _kbAnimDuration = Duration(milliseconds: 260);
  static const _kbAnimCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _primary,
      body: Column(
        children: [
          // ── VIDEO HEADER ────────────────────────────────────────────
          // Collapses in place (not scrolled away) when a field is
          // focused, so the form + button stay visible above the
          // keyboard without needing to scroll.
          AnimatedContainer(
            duration: _kbAnimDuration,
            curve: _kbAnimCurve,
            height: keyboardVisible ? topPadding + 158 : size.height * 0.5,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _LoginBackgroundVideo(),
                // Brand tint over the footage (our own maroon/pink, not the
                // reference layout's green) so the white logo/headline stay
                // readable regardless of what's playing behind them.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _accent.withOpacity(0.55),
                        _primary.withOpacity(0.88),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: topPadding + 4,
                  left: 12,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                // Bottom-anchored so it reads as "near the top" in both the
                // tall idle state and the collapsed keyboard-open state,
                // without needing separate layouts for each.
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: keyboardVisible ? 14 : 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The icon circle and wordmark are baked into one
                      // flat image at a fixed ratio (circle much taller
                      // than the text), so matching a reference lockup's
                      // icon:wordmark proportion means cropping+scaling the
                      // two regions independently rather than resizing the
                      // whole image - see _LogoSprite. Left margin comes
                      // from the shared Positioned(left: 20) above, same as
                      // every other element in this column.
                      //
                      // Sized so the "Docwellness" wordmark's cap-height
                      // matches "Welcome back" (measured directly off a
                      // device screenshot, not the source PNG's crop ratio -
                      // that theoretical calc undershot in practice), minus
                      // a further 2dp trim. Matching the wordmark to the
                      // full two-line name+slogan height instead (as
                      // literally requested) was tried and rejected: it
                      // makes a single line of logo text as tall as two
                      // lines of body text, which reads as oversized even
                      // though the *block* heights then technically match.
                      // Icon height instead matches the wordmark+tagline
                      // sprite's height directly, so the icon spans the
                      // full name+subtitle block beside it.
                      // CrossAxisAlignment.start, not .center: the text
                      // sprite's box includes the tagline hanging below the
                      // wordmark, so centering by *box* height (as .center
                      // does) pulls the wordmark's true visual center above
                      // the icon's - the icon then reads as sitting too low.
                      // Both crops start with a similar small margin before
                      // their content begins, so top-aligning the boxes
                      // instead lines up the icon with the wordmark line
                      // itself, tagline hanging below unaffected.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LogoSprite(
                            srcRect: const Rect.fromLTWH(45, 55, 350, 330),
                            height: keyboardVisible ? 31 : 41,
                            duration: _kbAnimDuration,
                            curve: _kbAnimCurve,
                          ),
                          SizedBox(width: keyboardVisible ? 8 : 10),
                          _LogoSprite(
                            srcRect: const Rect.fromLTWH(415, 160, 520, 120),
                            height: keyboardVisible ? 31 : 41,
                            duration: _kbAnimDuration,
                            curve: _kbAnimCurve,
                          ),
                        ],
                      ),
                      AnimatedContainer(
                        duration: _kbAnimDuration,
                        curve: _kbAnimCurve,
                        height: keyboardVisible ? 8 : 20,
                      ),
                      _AnimatedSizeText(
                        text: 'Welcome back',
                        fontWeight: FontWeight.w700,
                        fontSize: keyboardVisible ? 20 : 30,
                        color: Colors.white,
                        duration: _kbAnimDuration,
                        curve: _kbAnimCurve,
                      ),
                      const SizedBox(height: 6),
                      _AnimatedSizeText(
                        text: 'Sign in to continue your wellness journey',
                        fontWeight: FontWeight.w400,
                        fontSize: keyboardVisible ? 12 : 14,
                        color: Colors.white.withOpacity(0.85),
                        duration: _kbAnimDuration,
                        curve: _kbAnimCurve,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── FORM CARD ───────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: _bgLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── EMAIL ──────────────────────────────────────
                      const CustomText(
                        text: 'Email Address',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xff4D5761),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: controller.loginUserNameController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!GetUtils.isEmail(v.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          'Enter your email',
                          Icons.alternate_email,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── PASSWORD ──────────────────────────────────
                      const CustomText(
                        text: 'Password',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xff4D5761),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: controller.loginPasswordController,
                        obscureText: _obscurePassword,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter your password'
                            : null,
                        decoration:
                            _inputDecoration(
                              'Enter your password',
                              Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xff6C737F),
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                      ),

                      // ── ERROR ─────────────────────────────────────
                      Obx(
                        () => controller.loginError.value.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  controller.loginError.value,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 8),

                      // ── FORGOT PASSWORD ───────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () =>
                              Get.to(() => const ForgetPasswordScreen()),
                          child: const CustomText(
                            text: 'Forgot Password?',
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: _accent,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── SIGN IN BUTTON ────────────────────────────
                      Obx(
                        () => GestureDetector(
                          onTap: controller.isLoginLoading.value
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    await controller.login();
                                  }
                                },
                          child: Container(
                            height: 46,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: controller.isLoginLoading.value
                                  ? _primary.withOpacity(0.6)
                                  : _primary,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.30),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: controller.isLoginLoading.value
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const CustomText(
                                      text: 'Sign In',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff9CA3AF), fontSize: 14),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffEAD4E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

// ── ANIMATED HEADER TEXT ──────────────────────────────────────────────
// CustomText bakes its TextStyle in directly (no DefaultTextStyle
// inheritance), so AnimatedDefaultTextStyle can't drive it - this
// TweenAnimationBuilder interpolates the fontSize instead, letting the
// header text scale down in step with the collapsing header.
class _AnimatedSizeText extends StatelessWidget {
  const _AnimatedSizeText({
    required this.text,
    required this.fontWeight,
    required this.fontSize,
    required this.color,
    required this.duration,
    required this.curve,
  });

  final String text;
  final FontWeight fontWeight;
  final double fontSize;
  final Color color;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(end: fontSize),
      builder: (context, size, child) => CustomText(
        text: text,
        fontWeight: fontWeight,
        fontSize: size,
        color: color,
      ),
    );
  }
}

// ── ANIMATED HEADER LOGO (cropped sprite) ──────────────────────────────
// logo_horizontal.png bakes the icon circle and the wordmark+tagline into
// one flat image at a fixed relative size (the circle is much taller than
// the text) - there's no colorway asset tuned for a dark background
// either. This widget picks out a sub-rectangle of the source image (in
// its natural 963x436 pixel coordinates) and scales *that piece* to an
// arbitrary height, via the standard OverflowBox "sprite sheet" trick:
// render the full image at whatever scale makes srcRect map to `height`,
// then clip a window over just that region. Using it twice - once for the
// icon's srcRect, once for the wordmark+tagline's - lets the two scale
// independently instead of both being locked to the source's ratio, and
// the white tint (colorBlendMode.srcIn) still applies per-instance for
// the maroon header.
class _LogoSprite extends StatelessWidget {
  const _LogoSprite({
    required this.srcRect,
    required this.height,
    required this.duration,
    required this.curve,
  });

  static const double _naturalWidth = 963;
  static const double _naturalHeight = 436;

  final Rect srcRect;
  final double height;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(end: height),
      builder: (context, h, child) {
        final scale = h / srcRect.height;
        final displayWidth = srcRect.width * scale;
        final fullWidth = _naturalWidth * scale;
        final fullHeight = _naturalHeight * scale;
        final dw = displayWidth - fullWidth;
        final dh = h - fullHeight;
        final alignX = dw == 0 ? 0.0 : (-2 * (srcRect.left * scale) / dw) - 1;
        final alignY = dh == 0 ? 0.0 : (-2 * (srcRect.top * scale) / dh) - 1;

        return ClipRect(
          child: SizedBox(
            width: displayWidth,
            height: h,
            child: OverflowBox(
              minWidth: fullWidth,
              maxWidth: fullWidth,
              minHeight: fullHeight,
              maxHeight: fullHeight,
              alignment: Alignment(alignX, alignY),
              child: Image.asset(
                'assets/icons/logo_horizontal.png',
                width: fullWidth,
                height: fullHeight,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── BACKGROUND VIDEO ──────────────────────────────────────────────────
// Same clip as the first welcome screen (see auth_view.dart's
// _OnboardingVideo, assets/videos/onboarding_intro.mp4) - reused here as a
// full-bleed cover background (FittedBox+BoxFit.cover trick, since
// VideoPlayer alone only ever renders at its native aspect ratio) instead
// of that screen's rounded, aspect-ratio-boxed inline player.
class _LoginBackgroundVideo extends StatefulWidget {
  const _LoginBackgroundVideo();

  @override
  State<_LoginBackgroundVideo> createState() => _LoginBackgroundVideoState();
}

class _LoginBackgroundVideoState extends State<_LoginBackgroundVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/onboarding_intro.mp4',
    );
    _controller.setLooping(true);
    _controller.setVolume(0);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const ColoredBox(color: Color(0xff530630));
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
