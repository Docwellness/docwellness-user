import 'package:docwellness/app/modules/home/controllers/water_controller.dart';
import 'package:docwellness/app/modules/home/widgets/water_history_chart.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class WaterIntakeContainer extends StatelessWidget {
  const WaterIntakeContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final WaterController wc = Get.find<WaterController>();
    return _WaterIntakeBody(wc: wc);
  }
}

class _WaterIntakeBody extends StatefulWidget {
  final WaterController wc;
  const _WaterIntakeBody({required this.wc});

  @override
  State<_WaterIntakeBody> createState() => _WaterIntakeBodyState();
}

class _WaterIntakeBodyState extends State<_WaterIntakeBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  bool _showChart = false;
  Worker? _intakeWorker;
  Worker? _goalWorker;

  WaterController get _wc => widget.wc;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);

    // Keep lottie in sync with water progress (listen to both intake & goal)
    _intakeWorker = ever(_wc.currentIntake, (_) {
      if (mounted) {
        _lottieController.value = _wc.progressPercent;
      }
    });
    _goalWorker = ever(_wc.dailyGoal, (_) {
      if (mounted) {
        _lottieController.value = _wc.progressPercent;
      }
    });

    // Set initial lottie value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lottieController.value = _wc.progressPercent;
      }
    });
  }

  @override
  void dispose() {
    _intakeWorker?.dispose();
    _goalWorker?.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Main water intake card ---
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffFEF6FB),
            border: cardBorder,
            borderRadius: BorderRadius.circular(16),
            boxShadow: cardShadow,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 52,
                    width: 45,
                    child: Lottie.asset(
                      'assets/levels/water animation.json',
                      controller: _lottieController,
                      fit: BoxFit.contain,
                      delegates: LottieDelegates(
                        values: [
                          ValueDelegate.color(const [
                            '**',
                          ], value: const Color(0xFFDE2493)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      runSpacing: 8,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomText(
                              text: 'Water Intake',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xff384250),
                            ),
                            Obx(
                              () => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFCE7F6),
                                      border: Border.all(
                                        color: const Color(0xffEF45B2),
                                      ),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Center(
                                      child: CustomText(
                                        text:
                                            '${_wc.currentIntakeFormatted} Liter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: const Color(0xff851653),
                                      ),
                                    ),
                                  ),
                                  CustomText(
                                    text: ' of ${_wc.goalFormatted} Liter ',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: const Color(0xff6C737F),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // + / - buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _wc.removeWater(),
                              child: Image.asset(
                                'assets/icons/Minus.png',
                                height: 30,
                                width: 30,
                                colorBlendMode: BlendMode.srcIn,
                                color: const Color(0xff0D121C),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Obx(
                              () => CustomText(
                                text:
                                    '${_wc.stepSize.value.toStringAsFixed(2)} L',
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                                color: const Color(0xffC11576),
                              ),
                            ),
                            const SizedBox(width: 15),
                            GestureDetector(
                              onTap: () => _wc.addWater(),
                              child: Image.asset(
                                'assets/icons/Plus.png',
                                height: 30,
                                width: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // --- Progress bar ---
              Obx(
                () => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _wc.progressPercent,
                    minHeight: 8,
                    backgroundColor: const Color(0xffFCE7F6),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xffC11576),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- Sync + Chart toggle ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => GestureDetector(
                      onTap: () => _wc.syncToBackend(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _wc.isSyncing.value
                                ? Icons.sync
                                : Icons.cloud_upload_outlined,
                            size: 16,
                            color: const Color(0xffC11576),
                          ),
                          const SizedBox(width: 4),
                          CustomText(
                            text: _wc.isSyncing.value
                                ? 'Syncing...'
                                : 'Sync now',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xffC11576),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _showChart = !_showChart);
                      if (_showChart) _wc.fetchHistory();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showChart
                              ? Icons.expand_less
                              : Icons.bar_chart_rounded,
                          size: 16,
                          color: const Color(0xffC11576),
                        ),
                        const SizedBox(width: 4),
                        CustomText(
                          text: _showChart ? 'Hide chart' : '7-day chart',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xffC11576),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- 7-Day Chart (expandable) ---
        if (_showChart)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Obx(() => WaterHistoryChart(history: _wc.history.toList())),
          ),
      ],
    );
  }
}
