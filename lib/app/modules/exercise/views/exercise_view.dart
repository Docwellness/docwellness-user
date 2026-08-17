import 'package:docwellness/app/modules/exercise/controllers/exercise_controller.dart';
import 'package:docwellness/app/modules/exercise/models/exercise_stats_model.dart';
import 'package:docwellness/app/modules/exercise/widgets/exercise_details_sheet.dart';
import 'package:docwellness/app/services/recipe_language_service.dart';
import 'package:docwellness/shared/widgets/week_day_strip.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:docwellness/utils/functions/link_launcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class _CategoryStyle {
  final IconData icon;
  final Color color;
  const _CategoryStyle(this.icon, this.color);
}

const Map<String, _CategoryStyle> _categoryStyles = {
  'Cardio': _CategoryStyle(Icons.directions_run_rounded, Color(0xffE5484D)),
  'Strength': _CategoryStyle(Icons.fitness_center_rounded, Color(0xff851653)),
  'Flexibility': _CategoryStyle(
    Icons.self_improvement_rounded,
    Color(0xff7C5CFC),
  ),
  'Sports': _CategoryStyle(Icons.sports_tennis_rounded, Color(0xff0EA5E9)),
  'Other': _CategoryStyle(Icons.sports_gymnastics_rounded, Color(0xff6C737F)),
};

_CategoryStyle _styleFor(String category) =>
    _categoryStyles[category] ?? _categoryStyles['Other']!;

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Mon-Sun day strip for browsing/logging any day in the current calendar
/// week - shares WeekDayStrip with diet_view.dart's day cells so the two
/// stay visually identical, scoped down since ExercisePlan has no
/// week-numbering of its own to select between (see
/// ExerciseController.currentWeekStart).
class _DayStrip extends StatelessWidget {
  const _DayStrip();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExerciseController>();
    return Obx(
      () => WeekDayStrip(
        weekStart: controller.currentWeekStart,
        selectedDate: controller.selectedDate.value,
        onDaySelected: controller.switchDate,
        expand: true,
      ),
    );
  }
}

/// A selected day's assigned exercises + a Log action, with a Mon-Sun day
/// strip (see _DayStrip) to browse/log any day in the current week -
/// mirrors diet_view.dart's day-at-a-glance pattern. Content language
/// reuses RecipeLanguageService (the same app-wide preference recipes use,
/// set from Settings) rather than a separate exercise-specific toggle.
class ExerciseView extends StatelessWidget {
  // Optional replacement for the AppBar title - DietAndExerciseScreen passes
  // its Diet Plan/Exercises pill switcher here so this screen's own AppBar
  // becomes the combined tab's single header instead of stacking a second
  // one above it. Standalone (Routes.EXERCISE) leaves this null and gets
  // the plain "Exercise Plan" title - the route itself is no longer linked
  // from anywhere in the app (Home's "Log Exercise" now switches to
  // DietAndExerciseScreen's Exercises pill instead, so the bottom nav bar
  // stays visible - see DietController.focusModeRequest), kept only in
  // case a future deep link wants a standalone entry point.
  final Widget? headerSwitcher;
  const ExerciseView({super.key, this.headerSwitcher});

  static const _accent = Color(0xff851653);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ExerciseController>()
        ? Get.find<ExerciseController>()
        : Get.put(ExerciseController());
    // Idempotent (see RecipeLanguageService.load's own doc comment) - safe
    // to fire on every build, only actually hits disk once.
    RecipeLanguageService.instance.load();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        centerTitle: false,
        title:
            headerSwitcher ??
            const CustomText(
              text: 'Exercise Plan',
              color: Color(0xff1F2A37),
              fontWeight: FontWeight.w400,
              fontSize: 21,
            ),
      ),
      body: Column(
        children: [
          // Stays visible across a day switch's refetch (unlike the rest of
          // the body below, gated on isLoading) so tapping a day doesn't
          // make the strip itself flash away and back.
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _DayStrip(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: _accent));
              }

              final stats = controller.stats.value;
              // Read here (inside this Obx's own builder) so language changes
              // reactively rebuild this whole tree - see the GetX reactivity note
              // in _ExerciseTile: a value read here and passed down as a plain
              // param stays tracked, but reading it inside a separate
              // StatelessWidget's own build() would not be.
              final language = RecipeLanguageService.instance.current.value;

              if (!controller.hasActivePlan.value) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CustomText(
                      text:
                          'No exercise plan assigned yet - check back once your dietician sets one up.',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: const Color(0xff6C737F),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: _accent,
                onRefresh: () => controller.fetchTodayStats(date: controller.selectedDate.value),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffFEF6FB), Color(0xffFDF2FA)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: cardBorder,
                  boxShadow: cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: _accent,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            CustomText(
                              text: controller.isSelectedDateFuture
                                  ? 'Planned Calories'
                                  : _isSameDate(controller.selectedDate.value, DateTime.now())
                                  ? 'Calories Burned Today'
                                  : 'Calories Burned',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: const Color(0xff6C737F),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        CustomText(
                          text: '${stats.totalCaloriesBurned}',
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                          color: const Color(0xff530630),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText(
                        text:
                            '${stats.completedCount}/${stats.totalExercises} done',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (RecipeLanguageService.supportedLanguages.length > 1) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: RecipeLanguageService.supportedLanguages.map((
                    lang,
                  ) {
                    final isSelected = language == lang;
                    return GestureDetector(
                      onTap: () =>
                          RecipeLanguageService.instance.setLanguage(lang),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff1F2A37)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xff1F2A37)
                                : const Color(0xffE5E7EB),
                          ),
                        ),
                        child: CustomText(
                          text: lang,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xff384250),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              if (stats.plannedExercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CustomText(
                      text: _isSameDate(controller.selectedDate.value, DateTime.now())
                          ? 'No exercises assigned for today'
                          : 'No exercises assigned for this day',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: const Color(0xff6C737F),
                    ),
                  ),
                )
              else
                ...stats.plannedExercises.map(
                  (exercise) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExerciseTile(
                      exercise: exercise,
                      controller: controller,
                      language: language,
                    ),
                  ),
                ),
            ],
          ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Same extraction patterns as home/widgets/videos_section.dart's
/// _extractYoutubeId - returns null for a non-YouTube link, which callers
/// treat as "open externally" instead.
String? _extractYoutubeId(String url) {
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

Future<void> _openExerciseVideo(
  BuildContext context,
  String videoUrl,
  String title,
) async {
  final ytId = _extractYoutubeId(videoUrl);
  if (ytId != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ExerciseVideoPlayer(videoId: ytId, title: title),
      ),
    );
    return;
  }
  await openWebLink(url: videoUrl, title: title);
}

class _ExerciseTile extends StatefulWidget {
  final PlannedExercise exercise;
  final ExerciseController controller;
  final String language;
  const _ExerciseTile({
    required this.exercise,
    required this.controller,
    required this.language,
  });

  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  static const _accent = Color(0xff851653);
  static const _done = Color(0xff1F8A5B);

  bool _instructionsExpanded = false;

  Future<void> _openLogDialog(BuildContext context) async {
    final exercise = widget.exercise;
    final durationController = TextEditingController(
      text: exercise.durationMinutes?.round().toString() ?? '',
    );
    final setsController = TextEditingController(
      text: exercise.sets?.round().toString() ?? '',
    );
    final repsController = TextEditingController(
      text: exercise.reps?.round().toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText(
          text: exercise.isLogged
              ? 'Edit ${exercise.nameIn(widget.language)}'
              : exercise.nameIn(widget.language),
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: const Color(0xff530630),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes, optional)',
              ),
            ),
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets (optional)'),
            ),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Un-log - same idea as Log Meal's portion-back-to-0 (see
          // LogMealContainer), just as an explicit button here since
          // exercises have no single "portion" field to zero out. Only
          // meaningful for an already-logged exercise.
          if (exercise.isLogged)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await widget.controller.removeExerciseLog(exercise.exerciseId);
                if (!success) {
                  showAppToast(
                    Get.overlayContext!,
                    message: 'Could not remove this log. Please try again.',
                    type: AppToastType.error,
                  );
                }
              },
              child: const Text('Un-log', style: TextStyle(color: Color(0xffD64545))),
            ),
          TextButton(
            onPressed: () async {
              final duration = int.tryParse(durationController.text.trim());
              Navigator.pop(context);
              // Duration is optional - if left blank, the backend estimates
              // it from the plan's assigned duration/sets or the exercise
              // catalog's average time-per-rep (see submitExerciseLog).
              // Re-logging an already-logged exercise (isLogged == true)
              // overwrites its existing log entry for today rather than
              // creating a duplicate - same POST /exercise-log endpoint,
              // this dialog just doubles as the edit form.
              final success = await widget.controller.logExercise(
                exerciseId: exercise.exerciseId,
                durationMinutes: (duration != null && duration > 0) ? duration : null,
                sets: int.tryParse(setsController.text.trim()),
                reps: int.tryParse(repsController.text.trim()),
              );
              if (!success) {
                showAppToast(
                  Get.overlayContext!,
                  message: exercise.isLogged
                      ? 'Could not update this exercise log. Please try again.'
                      : 'Could not log this exercise. Please try again.',
                  type: AppToastType.error,
                );
              }
            },
            child: Text(
              exercise.isLogged ? 'Update' : 'Log',
              style: const TextStyle(fontWeight: FontWeight.w700, color: _accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final style = _styleFor(exercise.category);
    final instructions = exercise.instructionsIn(widget.language);

    return GestureDetector(
      onTap: () => showExerciseDetailsSheet(
        context,
        exercise: exercise,
        language: widget.language,
        onLogTap: _openLogDialog,
        isFuture: widget.controller.isSelectedDateFuture,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: exercise.isLogged
              ? const Color(0xffF0FBF6)
              : const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: exercise.isLogged
                ? const Color(0xffBEE8D4)
                : const Color(0xffFCE7F6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        style.color.withValues(alpha: 0.85),
                        style.color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    exercise.isLogged ? Icons.check_rounded : style.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: exercise.nameIn(widget.language),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xff1F2A37),
                      ),
                      CustomText(
                        text: (() {
                          final parts = [
                            if (exercise.durationMinutes != null)
                              '${exercise.durationMinutes!.round()} min',
                            if (exercise.sets != null)
                              '${exercise.sets!.round()} sets',
                            if (exercise.reps != null)
                              '${exercise.reps!.round()} reps',
                          ];
                          return parts.isEmpty
                              ? 'No target set - log your own duration'
                              : parts.join(' • ');
                        })(),
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: const Color(0xff6C737F),
                      ),
                    ],
                  ),
                ),
                if (exercise.isLogged)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 22, color: _done),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: CustomButton(
                          onTap: () => _openLogDialog(context),
                          text: 'Edit',
                          isOutline: true,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                // A future day (previewing what's coming, same as
                // diet_view.dart's day strip) has nothing to log yet.
                else if (!widget.controller.isSelectedDateFuture)
                  SizedBox(
                    width: 90,
                    child: CustomButton(
                      onTap: () => _openLogDialog(context),
                      text: 'Log',
                      isOutline: false,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            if (exercise.descriptionIn(widget.language).isNotEmpty) ...[
              const SizedBox(height: 10),
              CustomText(
                text: exercise.descriptionIn(widget.language),
                fontWeight: FontWeight.w400,
                fontSize: 12.5,
                color: const Color(0xff384250),
              ),
            ],
            Row(
              children: [
                if (exercise.videoUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openExerciseVideo(
                      context,
                      exercise.videoUrl,
                      exercise.nameIn(widget.language),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 10, right: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            size: 18,
                            color: _accent,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Watch demo',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (instructions.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(
                      () => _instructionsExpanded = !_instructionsExpanded,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _instructionsExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: _accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _instructionsExpanded
                                ? 'Hide steps'
                                : 'How to do it',
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (_instructionsExpanded && instructions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: instructions
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: style.color,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomText(
                                  text: entry.value,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12.5,
                                  color: const Color(0xff384250),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Simple embedded YouTube player for an exercise demo video - a scoped-down
/// sibling of home/widgets/videos_section.dart's _FullScreenYoutubePlayer
/// (no landscape auto-rotate/seek-bar controls needed for a short demo clip).
class _ExerciseVideoPlayer extends StatefulWidget {
  final String videoId;
  final String title;
  const _ExerciseVideoPlayer({required this.videoId, required this.title});

  @override
  State<_ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<_ExerciseVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        foregroundColor: const Color(0xff1F2A37),
        title: CustomText(
          text: widget.title,
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: const Color(0xff1F2A37),
        ),
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressColors: const ProgressBarColors(
            playedColor: Color(0xff851653),
            handleColor: Color(0xff851653),
          ),
        ),
      ),
    );
  }
}
