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
  final AuthController controller = Get.put(AuthController());
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  static const _primary = Color(0xff530630);
  static const _accent = Color(0xff851653);
  static const _bgLight = Color(0xffFDF2FA);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _primary,
      body: Column(
        children: [
          // ── VIDEO HEADER ────────────────────────────────────────────
          SizedBox(
            height: size.height * 0.5,
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
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                'assets/icons/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const CustomText(
                              text: 'DocWellness',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const Spacer(),
                        const CustomText(
                          text: 'Welcome back',
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        CustomText(
                          text: 'Sign in to continue your wellness journey',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ],
                    ),
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
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── EMAIL / USERNAME ──────────────────────────
                      // AuthController.login() accepts either (see its
                      // isEmail branch), so this stays flexible rather than
                      // narrowing to "Email Address" like the reference.
                      const CustomText(
                        text: 'Email or Username',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xff4D5761),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.loginUserNameController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter your email or username'
                            : null,
                        decoration: _inputDecoration(
                          'Enter your email or username',
                          Icons.alternate_email,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── PASSWORD ──────────────────────────────────
                      const CustomText(
                        text: 'Password',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xff4D5761),
                      ),
                      const SizedBox(height: 8),
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
                                padding: const EdgeInsets.only(top: 12),
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

                      const SizedBox(height: 12),

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

                      const SizedBox(height: 24),

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
                            height: 54,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
