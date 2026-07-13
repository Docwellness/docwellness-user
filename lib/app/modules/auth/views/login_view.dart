import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
          // ── BRANDED HEADER ──────────────────────────────────────────
          SizedBox(
            height: size.height * 0.33,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'assets/icons/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const CustomText(
                          text: 'DocWellness',
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        CustomText(
                          text: 'Your health journey starts here',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
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
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(
                        text: 'Welcome back!',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: _primary,
                      ),
                      const SizedBox(height: 6),
                      const CustomText(
                        text: 'Sign in to continue your wellness journey',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff6C737F),
                      ),

                      const SizedBox(height: 32),

                      // ── USERNAME ──────────────────────────────────
                      TextFormField(
                        controller: controller.loginUserNameController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter your username'
                            : null,
                        decoration: _inputDecoration(
                          'Username',
                          Icons.person_outline_rounded,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── PASSWORD ──────────────────────────────────
                      TextFormField(
                        controller: controller.loginPasswordController,
                        obscureText: _obscurePassword,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter your password'
                            : null,
                        decoration:
                            _inputDecoration(
                              'Password',
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

                      const SizedBox(height: 32),

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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xff4D5761)),
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
