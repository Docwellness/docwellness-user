import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/models/message_model.dart';
import 'app/modules/diet/controllers/diet_controller.dart';
import 'app/modules/home/controllers/water_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/services/socket_service.dart';

String? userId;
String? token;
String? role;

const bool testMode = false;
const String testPatientId = '698097813b0d03d888c0ce52';
const String testPatientToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5ODA5NzgxM2IwZDAzZDg4OGMwY2U1MiIsImlhdCI6MTc3MTA2MDExMywiZXhwIjoxNzczNjUyMTEzfQ.bXaAJokFGfT4NT16r-javnQCXbyG3jIKP9n8ifJ3pEM';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await getUserData();

  // Suppress raw Flutter framework errors — never show red crash screens
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: false);
  };
  // Replace red error widget with blank box so nothing leaks to user
  ErrorWidget.builder = (_) => const SizedBox.shrink();

  // For testing: override with test credentials
  if (testMode) {
    userId = testPatientId;
    token = testPatientToken;
    role = 'patient';
    debugPrint('🧪 TEST MODE: userId=$userId');
  }

  // Initialize socket service if user is logged in
  if (userId != null && userId!.isNotEmpty) {
    Get.put(SocketService());
    Get.lazyPut<DietController>(() => DietController(), fenix: true);
    // Permanent WaterController so 11 PM auto-sync timer survives navigation
    Get.put<WaterController>(WaterController(), permanent: true);
    MessageModel.setCurrentUserId(userId!);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Application",
      initialRoute: userId == null || userId!.isEmpty
          ? Routes.AUTH
          : AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xffFEF6FB),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1F2A37),
          ),
          contentTextStyle: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xff4D5761),
            height: 1.4,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xff530630)),
        ),
      ),
      onInit: () {
        // Connect socket after app initializes (deferred to avoid blocking startup)
        if (userId != null && userId!.isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            try {
              final socketService = Get.find<SocketService>();
              socketService.init();
            } catch (e) {
              log('Socket service not initialized: $e');
            }
          });
        }
      },
    );
  }
}

Future<void> getUserData() async {
  final SharedPreferences pref = await SharedPreferences.getInstance();
  userId = pref.getString('userId');
  token = pref.getString('token');
  role = pref.getString('role');

  debugPrint('----------------userId: $userId');
  log('--------$token');
}
