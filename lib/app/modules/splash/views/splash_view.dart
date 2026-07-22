import 'package:docwellness/app/modules/auth/views/personal_info_view.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Plain launch screen: brand background, logo - nothing else. The stacked
/// logo (assets/icons/logo.png) already bakes in the "Docwellness" wordmark
/// and tagline, so no separate text widget is needed here. Shown for a
/// fixed short delay then replaces itself with the real destination
/// (Get.offNamed/Get.off, not Get.to, so it's never left on the
/// back-stack) - same AUTH-vs-HOME choice main.dart's GetMaterialApp used
/// to make directly via the userId global before this screen existed, plus
/// a third "resume onboarding" branch - see initState. Deliberately
/// navigates to Routes.HOME, not AppPages.INITIAL - INITIAL now points at
/// this splash screen itself (see app_pages.dart), so referencing it here
/// would just loop back to the splash.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (userId != null && userId!.isNotEmpty) {
        Get.offNamed(Routes.HOME);
      } else if (token != null && token!.isNotEmpty) {
        // Email verified in a previous session but onboarding/registration
        // was never finished (see main.dart's getUserData) - resume there
        // instead of sending them back to the welcome/signup screen.
        Get.off(() => const PersonalInfoView());
      } else {
        Get.offNamed(Routes.AUTH);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFEF6FB),
      body: Center(
        child: Image.asset('assets/icons/logo.png', width: 260),
      ),
    );
  }
}
