import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/controllers/water_controller.dart';
import 'package:docwellness/app/modules/home/widgets/water_history_chart.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

// No longer wraps itself in its own bordered Container - the Home screen
// merges this into the same card as ProgressCard (see home_view.dart),
// separated by a dashed divider, so the outer decoration lives there now.
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
  Worker? _viewedIntakeWorker;
  Worker? _selectedDateWorker;

  WaterController get _wc => widget.wc;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);

    // Keep lottie in sync with whatever's actually on screen - today's live
    // progress, or a browsed-to day's fetched total.
    void syncLottie() {
      if (mounted) _lottieController.value = _wc.displayProgressPercent;
    }

    _intakeWorker = ever(_wc.currentIntake, (_) => syncLottie());
    _goalWorker = ever(_wc.dailyGoal, (_) => syncLottie());
    _viewedIntakeWorker = ever(_wc.viewedIntake, (_) => syncLottie());

    // The Home screen's day-navigator (Today ◀ ▶) drives which day this
    // card shows - mirrors ProgressCard's own date-driven refresh so water
    // stays in sync with whichever day the patient is actually looking at
    // instead of always showing today's figure.
    final homeController = Get.find<HomeController>();
    _wc.setViewedDate(homeController.selectedDate.value);
    _selectedDateWorker = ever<DateTime>(homeController.selectedDate, (date) {
      _wc.setViewedDate(date);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => syncLottie());
  }

  @override
  void dispose() {
    _intakeWorker?.dispose();
    _goalWorker?.dispose();
    _viewedIntakeWorker?.dispose();
    _selectedDateWorker?.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                                  text: _wc.isLoadingViewedDay.value
                                      ? '...'
                                      : '${_wc.displayIntakeFormatted} Liter',
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
                  // + / - buttons only make sense for today - a past day's
                  // water total is a read-only historical figure, not
                  // something you can retroactively log against.
                  Obx(
                    () => _wc.isViewingToday
                        ? Row(
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
                              CustomText(
                                text:
                                    '${_wc.stepSize.value.toStringAsFixed(2)} L',
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                                color: const Color(0xffC11576),
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
                          )
                        : const SizedBox.shrink(),
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
              value: _wc.displayProgressPercent,
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
            // "Sync now" pushes today's local entries to the backend -
            // meaningless for a past day, which is already whatever the
            // backend has on record.
            Obx(
              () => _wc.isViewingToday
                  ? GestureDetector(
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
                    )
                  : const SizedBox.shrink(),
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
