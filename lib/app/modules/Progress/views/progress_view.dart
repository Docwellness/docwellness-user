import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:docwellness/app/modules/Progress/views/log_body_data_view.dart';
import 'package:docwellness/app/modules/goal_journey/widgets/journey_card.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:docwellness/app/modules/Progress/widgets/big_achievement_container.dart';
import 'package:docwellness/app/modules/Progress/widgets/bmi_chart.dart';
import 'package:docwellness/app/modules/Progress/widgets/calorie_container.dart';
import 'package:docwellness/app/modules/Progress/widgets/calorie_intake.dart';
import 'package:docwellness/app/modules/Progress/widgets/date_range_selector_button.dart';
import 'package:docwellness/app/modules/Progress/widgets/journey_widget.dart';
import 'package:docwellness/app/modules/Progress/widgets/line_chart.dart';
import 'package:docwellness/app/modules/Progress/widgets/weight_info_row.dart';
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/widgets/log_meal_sheet.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/progress_controller.dart';

class ProgressView extends GetView<ProgressController> {
  const ProgressView({super.key});

  static final GlobalKey _captureKey = GlobalKey();
  static final ScrollController _scrollController = ScrollController();

  /// Logging meals/body data only makes sense once the diet plan itself has
  /// started (same gate Home uses for its subscription banner/countdown -
  /// see HomeController.dietEnabled) - before that there's no active plan
  /// day to log against.
  bool get _dietStarted =>
      Get.isRegistered<HomeController>() &&
      Get.find<HomeController>().dietEnabled.value;

  /// Earliest date any chart's date-range picker allows - the diet plan's
  /// real start date (see ProgressController.dietStartDate, populated from
  /// the tracking-data endpoint's weekSchedule-anchored planStartDate).
  /// Falls back to today only in the brief window before the first
  /// tracking-data response has come back.
  DateTime _firstSelectableDate(ProgressController c) =>
      c.dietStartDate.value ?? DateTime.now();

  /// Scrolls through the page, captures each viewport, and stitches them
  /// into one tall long-screenshot image.
  Future<Uint8List?> _captureScreenImage(BuildContext context) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Cap pixel ratio to avoid huge memory usage on hi-DPI devices
      final pixelRatio = MediaQuery.of(
        context,
      ).devicePixelRatio.clamp(1.0, 2.5);
      final viewportW = boundary.size.width;
      final viewportH = boundary.size.height;

      // If scroll controller not attached, fallback to single capture
      if (!_scrollController.hasClients ||
          _scrollController.position.maxScrollExtent <= 0) {
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return byteData?.buffer.asUint8List();
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      final originalScroll = _scrollController.position.pixels;

      // AppBar + status bar height
      final topPadding = MediaQuery.of(context).padding.top;
      final appBarH = kToolbarHeight + topPadding;
      final bodyH = viewportH - appBarH;

      if (bodyH <= 0) return null;

      // Total content height and output image height
      final totalContentH = bodyH + maxScroll;
      final totalOutputH = appBarH + totalContentH;

      // Capture at each scroll position
      final scrollPositions = <double>[];
      final images = <ui.Image>[];

      double scrollPos = 0;
      while (true) {
        final clamped = scrollPos.clamp(0.0, maxScroll);
        _scrollController.jumpTo(clamped);
        await Future.delayed(const Duration(milliseconds: 80));
        await WidgetsBinding.instance.endOfFrame;

        final img = await boundary.toImage(pixelRatio: pixelRatio);
        scrollPositions.add(clamped);
        images.add(img);

        if (clamped >= maxScroll) break;
        scrollPos += bodyH;
      }

      // Restore original scroll position
      _scrollController.jumpTo(originalScroll);

      if (images.isEmpty) return null;

      // Stitch all captures into one tall image
      final pr = pixelRatio;
      final outW = (viewportW * pr).ceil();
      final outH = (totalOutputH * pr).ceil();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
      );
      // White background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );

      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        final scroll = scrollPositions[i];

        if (i == 0) {
          // First capture: draw full image (AppBar + first body chunk)
          canvas.drawImage(img, Offset.zero, Paint());
        } else {
          // Subsequent: crop AppBar from source, place body at correct y
          final srcTop = appBarH * pr;
          final srcH = bodyH * pr;
          final dstTop = (appBarH + scroll) * pr;

          canvas.drawImageRect(
            img,
            Rect.fromLTWH(0, srcTop, outW.toDouble(), srcH),
            Rect.fromLTWH(0, dstTop, outW.toDouble(), srcH),
            Paint(),
          );
        }
      }

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(outW, outH);
      final byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      for (final img in images) {
        img.dispose();
      }
      finalImage.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing progress screen: $e');
      return null;
    }
  }

  Future<void> _shareCapturedScreen(BuildContext context) async {
    final bytes = await _captureScreenImage(context);
    if (bytes == null || bytes.isEmpty) {
      showAppToast(
        Get.overlayContext!,
        message: 'Could not capture screen. Please try again.',
        type: AppToastType.error,
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/progress_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);

    await Posthog().capture(eventName: 'progress_shared');
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'My progress update from Docwellness',
      ),
    );
  }

  Future<bool> _ensureGalleryPermission() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;

      final storage = await Permission.storage.request();
      return storage.isGranted;
    }

    if (Platform.isIOS) {
      final photos = await Permission.photosAddOnly.request();
      return photos.isGranted || photos.isLimited;
    }

    return true;
  }

  Future<void> _downloadCapturedScreen(BuildContext context) async {
    final hasPermission = await _ensureGalleryPermission();
    if (!hasPermission) {
      showAppToast(
        Get.overlayContext!,
        message:
            'Permission required: Please allow photo/storage access to save screenshots.',
        type: AppToastType.warning,
      );
      return;
    }

    final bytes = await _captureScreenImage(context);
    if (bytes == null || bytes.isEmpty) {
      showAppToast(
        Get.overlayContext!,
        message: 'Could not capture screen. Please try again.',
        type: AppToastType.error,
      );
      return;
    }

    final fileName = 'progress_${DateTime.now().millisecondsSinceEpoch}';
    final result = await ImageGallerySaverPlus.saveImage(
      bytes,
      quality: 100,
      name: fileName,
    );

    final isSuccess =
        result != null &&
        (result['isSuccess'] == true || result['success'] == true);

    if (isSuccess) {
      showAppToast(
        Get.overlayContext!,
        message: 'Screenshot downloaded to gallery.',
        type: AppToastType.success,
      );
      return;
    }

    showAppToast(
      Get.overlayContext!,
      message: 'Could not save screenshot. Check storage permissions.',
      type: AppToastType.error,
    );
  }

  void _showShareDownloadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: const Text('Share screenshot'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _shareCapturedScreen(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Download screenshot'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _downloadCapturedScreen(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _captureKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xffFDF2FA),
          title: Text(
            'Progress',
            style: TextStyle(
              color: Color(0xff1F2A37),
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _showShareDownloadSheet(context),
              icon: Icon(Icons.share, color: Color(0xff4D5761)),
            ),
            // IconButton(
            //   onPressed: () {},
            //   icon: Icon(Icons.more_vert_sharp, color: Color(0xff4D5761)),
            // ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.refreshAll(),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: CustomText(
                    text: 'Weight loss/gain (in KG)',

                    fontWeight: FontWeight.w400,
                    fontSize: 19,
                    color: Color(0xff9F1561),
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Obx(
                    () => WeightInfoRow(
                      currentWeight: controller.currentWeight.value,
                      targetWeight: controller.targetWeight.value,
                      initialWeight: controller.startWeight.value,
                      percentageChange: controller.percentageChange.value,
                      progress: controller.targetWeight.value > 0
                          ? (controller.currentWeight.value /
                                    controller.targetWeight.value)
                                .clamp(0.0, 1.0)
                          : 0.0,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                const JourneyCard(),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Obx(() {
                    final now = DateTime.now();
                    return BmiChart(
                      bmiData: controller.bmiTrend.toList(),
                      currentBmi: controller.currentBMI.value,
                      rangeStart: controller.bmiRangeStart.value ?? now,
                      rangeEnd: controller.bmiRangeEnd.value ?? now,
                      firstSelectableDate: _firstSelectableDate(controller),
                      lastSelectableDate: now,
                      onRangeSelected: controller.changeBmiRange,
                      currentIndex: controller.bmiCurrentIndex.value,
                    );
                  }),
                ),
                SizedBox(height: 16),
                // Body Measurements Row (Arm, Waist, Hip) — right after BMI chart per design
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: customContainer(
                            title: "Arm",
                            value: controller.armMeasurement.value > 0
                                ? controller.armMeasurement.value
                                      .toStringAsFixed(0)
                                : '--',
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: customContainer(
                            title: "Waist",
                            value: controller.waistMeasurement.value > 0
                                ? controller.waistMeasurement.value
                                      .toStringAsFixed(0)
                                : '--',
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: customContainer(
                            title: "Hip",
                            value: controller.hipMeasurement.value > 0
                                ? controller.hipMeasurement.value
                                      .toStringAsFixed(0)
                                : '--',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomText(
                          text: 'Weight trend over time (in KG)',

                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff9F1561),
                        ),
                      ),

                      Obx(() {
                        final now = DateTime.now();
                        return DateRangeSelectorButton(
                          selectedStart:
                              controller.weightRangeStart.value ?? now,
                          selectedEnd: controller.weightRangeEnd.value ?? now,
                          firstDate: _firstSelectableDate(controller),
                          lastDate: now,
                          onRangeSelected: controller.changeWeightRange,
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Obx(() {
                    return TargetWeightChart(
                      weightData: controller.weightTrend.toList(),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Obx(() {
                    final dr = controller.weightDateRange.value;
                    final first = dr?.start ?? '';
                    final last = dr?.end ?? '';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: first,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xffD2D6DB),
                        ),
                        if (last.isNotEmpty && last != first)
                          CustomText(
                            text: last,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xffD2D6DB),
                          ),
                      ],
                    );
                  }),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Obx(() {
                    final started = _dietStarted;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          // Kept as an always-live onTap (not CustomButton's
                          // own `enabled` flag) so a tap while disabled can
                          // still show the explanatory toast below -
                          // CustomButton(enabled: false) would silently
                          // swallow the tap instead.
                          opacity: started ? 1 : 0.5,
                          child: CustomButton(
                            onTap: () {
                              if (!started) {
                                showAppToast(
                                  context,
                                  message:
                                      'Log Body Data will be available once your diet plan starts.',
                                  type: AppToastType.warning,
                                );
                                return;
                              }
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                isScrollControlled: true,

                                useSafeArea: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    initialChildSize: 0.95,

                                    expand: false,
                                    builder: (context, scrollController) {
                                      return LogBodyDataView(
                                        scrollController: scrollController,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            text: 'Log Body Data',
                            isOutline: false,
                            fontSize: 15,
                          ),
                        ),
                        if (!started) ...[
                          SizedBox(height: 6),
                          CustomText(
                            text:
                                'Available once your diet plan starts.',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff9DA4AE),
                          ),
                        ],
                      ],
                    );
                  }),
                ),
                SizedBox(height: 16),

                // Weight Achievement Badge (dynamic from API)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Obx(() {
                    final weightAch = controller.achievements
                        .where((a) => a['type'] == 'weight_loss')
                        .toList();
                    if (weightAch.isEmpty) {
                      return BigAchievementContainer(
                        title: 'Keep going!',
                        description:
                            'Log your weight regularly to unlock achievements.',
                      );
                    }
                    return BigAchievementContainer(
                      title: weightAch.first['title'] ?? 'Achievement',
                      description: weightAch.first['description'] ?? '',
                    );
                  }),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xffFDF2FA),
                      border: cardBorder,
                      boxShadow: cardShadow,
                    ),

                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 13,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: 'Calorie intake',

                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff4D5761),
                                ),
                              ),

                              Obx(() {
                                final now = DateTime.now();
                                return DateRangeSelectorButton(
                                  selectedStart:
                                      controller.calorieRangeStart.value ??
                                      now,
                                  selectedEnd:
                                      controller.calorieRangeEnd.value ?? now,
                                  firstDate: _firstSelectableDate(controller),
                                  lastDate: now,
                                  onRangeSelected:
                                      controller.changeCalorieRange,
                                );
                              }),
                            ],
                          ),
                          SizedBox(height: 18),
                          Obx(
                            () => CalorieIntakeContainer(
                              data: controller.calorieData.toList(),
                              plannedCalories:
                                  controller.plannedDailyCalories.value,
                              currentIndex: controller.calorieCurrentIndex.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: secondCustomContainer(
                            title: "Today's Steps",
                            value: "--",
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: secondCustomContainer(
                            title: "Today's Calories",
                            value: controller.todayCalories.value > 0
                                ? '${controller.todayCalories.value}'
                                : '--',
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: secondCustomContainer(
                            title: "Today's Meals",
                            value:
                                '${controller.todayMealsLogged.value}/${controller.todayMealsPlanned.value}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Calorie Adherence Badge (dynamic from API)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Obx(() {
                    final calorieAch = controller.achievements
                        .where(
                          (a) =>
                              a['type'] == 'calorie_adherence' ||
                              a['type'] == 'consistency',
                        )
                        .toList();
                    if (calorieAch.isEmpty) {
                      return CalorieIntake(
                        title: 'Calorie tracking',
                        description:
                            'Log meals consistently to earn calorie achievements!',
                      );
                    }
                    return CalorieIntake(
                      title: calorieAch.first['title'] ?? 'Achievement',
                      description: calorieAch.first['description'] ?? '',
                    );
                  }),
                ),
                SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Obx(() {
                    final started = _dietStarted;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: started ? 1 : 0.5,
                          child: CustomButton(
                            onTap: () {
                              if (!started) {
                                showAppToast(
                                  context,
                                  message:
                                      'Log Meal will be available once your diet plan starts.',
                                  type: AppToastType.warning,
                                );
                                return;
                              }
                              Get.put((DietController()));

                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                useSafeArea: true,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    initialChildSize: 1,
                                    maxChildSize: 1,
                                    minChildSize: 0.5,
                                    expand: false,
                                    builder: (context, scrollController) {
                                      return LogMealSheet(
                                        scrollController: scrollController,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            text: 'Log Meal',
                            isOutline: false,
                            fontSize: 15,
                          ),
                        ),
                        if (!started) ...[
                          SizedBox(height: 6),
                          CustomText(
                            text:
                                'Available once your diet plan starts.',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff9DA4AE),
                          ),
                        ],
                      ],
                    );
                  }),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Obx(() {
                    final notes = controller.doctorNotes;
                    if (controller.isDoctorNotesLoading.value) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xffFEF6FB),
                          borderRadius: BorderRadius.circular(10),
                          border: cardBorder,
                          boxShadow: cardShadow,
                        ),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final doctorName = notes.isNotEmpty
                        ? (notes.first['doctorName'] ?? 'Your Doctor')
                        : 'Your Doctor';
                    final latestNote = notes.isNotEmpty
                        ? (notes.first['noteContent'] ?? '')
                        : 'No feedback yet. Your doctor will share notes with you here.';

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xffFEF6FB),
                        borderRadius: BorderRadius.circular(10),
                        border: cardBorder,
                        boxShadow: cardShadow,
                      ),
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 8,
                        bottom: 8,
                        right: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: "$doctorName's Feedback",
                            color: Color(0xff384250),
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                          ),
                          SizedBox(height: 6),
                          CustomText(
                            text: latestNote,
                            color: Color(0xff6C737F),
                            fontWeight: FontWeight.w400,
                            fontSize: 11.7,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                SizedBox(height: 6),

                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),

                  child: Divider(color: Color(0xffFCCEEF)),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: CustomText(
                    text: "Your Journey",

                    color: Color(0xff530630),
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 7),
                Obx(() {
                  if (controller.isJourneyLoading.value) {
                    return const SizedBox(
                      height: 253,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  // Use auto-generated milestone cards (from body logs)
                  final cards = controller.autoJourneyCards.isNotEmpty
                      ? controller.autoJourneyCards
                      : controller.journeyImages;
                  if (cards.isEmpty) {
                    return Container(
                      width: double.infinity,
                      height: 120,
                      color: Color(0xffFEF6FB),
                      child: Center(
                        child: CustomText(
                          text: "No journey images yet",
                          color: Color(0xff49454F),
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: double.infinity,
                    height: 253,
                    padding: EdgeInsets.symmetric(vertical: 13),
                    color: Color(0xffFEF6FB),
                    child: ListView.builder(
                      itemCount: cards.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: JourneyWidget(journeyImage: cards[index]),
                        );
                      },
                    ),
                  );
                }),

                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget customContainer({required String title, required String value}) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(10),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: title,

              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xff4D5761),
            ),

            CustomText(
              text: value,

              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xff111927),
            ),
          ],
        ),
      ),
    );
  }

  Widget secondCustomContainer({required String title, required String value}) {
    return Container(
      height: 79,
      decoration: BoxDecoration(
        color: title == "Today's Steps"
            ? Color(0xffF8FEF6)
            : const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(10),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: title,

              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xff4D5761),
            ),

            CustomText(
              text: value,

              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xff111927),
            ),
          ],
        ),
      ),
    );
  }
}
