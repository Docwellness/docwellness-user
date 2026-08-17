import 'package:docwellness/app/modules/exercise/models/exercise_stats_model.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/functions/link_launcher.dart';
import 'package:flutter/material.dart';
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

/// Full details view for one of today's assigned exercises - opened by
/// tapping a tile in exercise_view.dart. Mirrors the dietician app's
/// exercise_details_sheet.dart, scoped to the fields a PlannedExercise
/// actually carries (no MET/difficulty here - that's catalog-only data).
/// Reuses ExerciseController.logExercise for the Log action so both the
/// tile's own "Log" button and this sheet stay perfectly in sync.
Future<void> showExerciseDetailsSheet(
  BuildContext context, {
  required PlannedExercise exercise,
  required String language,
  required Future<void> Function(BuildContext) onLogTap,
  // A future day (previewing what's coming, same as diet_view.dart's day
  // strip) has nothing to log yet - hides the Log/Edit Log action below.
  bool isFuture = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => _ExerciseDetailsContent(
        exercise: exercise,
        language: language,
        scrollController: scrollController,
        onLogTap: onLogTap,
        isFuture: isFuture,
      ),
    ),
  );
}

class _ExerciseDetailsContent extends StatelessWidget {
  final PlannedExercise exercise;
  final String language;
  final ScrollController scrollController;
  final Future<void> Function(BuildContext) onLogTap;
  final bool isFuture;

  const _ExerciseDetailsContent({
    required this.exercise,
    required this.language,
    required this.scrollController,
    required this.onLogTap,
    this.isFuture = false,
  });

  static const _accent = Color(0xff851653);
  static const _done = Color(0xff1F8A5B);

  Widget _sectionTitle(String text, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: _styleFor(exercise.category).color),
          const SizedBox(width: 6),
        ],
        CustomText(
          text: text,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: const Color(0xff1F2A37),
        ),
      ],
    ),
  );

  Widget _chip(String text, {Color? color}) {
    final c = color ?? _accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: CustomText(
        text: text,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: c,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(exercise.category);
    final description = exercise.descriptionIn(language);
    final instructions = exercise.instructionsIn(language);
    final ytId = exercise.videoUrl.isNotEmpty
        ? _extractYoutubeId(exercise.videoUrl)
        : null;

    final targetParts = [
      if (exercise.durationMinutes != null)
        '${exercise.durationMinutes!.round()} min',
      if (exercise.sets != null) '${exercise.sets!.round()} sets',
      if (exercise.reps != null) '${exercise.reps!.round()} reps',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [style.color.withValues(alpha: 0.85), style.color],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: style.color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  exercise.isLogged ? Icons.check_rounded : style.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CustomText(
                    text: exercise.nameIn(language),
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: const Color(0xff1F2A37),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(exercise.category, color: style.color),
              if (targetParts.isNotEmpty) _chip(targetParts.join(' • ')),
              if (exercise.isLogged)
                _chip(
                  '${exercise.loggedCaloriesBurned.round()} kcal burned',
                  color: _done,
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            _sectionTitle('Description', icon: Icons.info_outline_rounded),
            CustomText(
              text: description,
              fontWeight: FontWeight.w400,
              fontSize: 13.5,
              color: const Color(0xff384250),
            ),
          ],
          if (ytId != null) ...[
            _sectionTitle(
              'Demo Video',
              icon: Icons.play_circle_outline_rounded,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: ytId,
                    flags: const YoutubePlayerFlags(
                      autoPlay: false,
                      mute: false,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (exercise.videoUrl.isNotEmpty) ...[
            _sectionTitle(
              'Demo Video',
              icon: Icons.play_circle_outline_rounded,
            ),
            GestureDetector(
              onTap: () => openWebLink(
                url: exercise.videoUrl,
                title: exercise.nameIn(language),
              ),
              child: CustomText(
                text: exercise.videoUrl,
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: _accent,
              ),
            ),
          ],
          if (instructions.isNotEmpty) ...[
            _sectionTitle('Instructions', icon: Icons.checklist_rounded),
            ...instructions.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
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
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        text: entry.value,
                        fontWeight: FontWeight.w400,
                        fontSize: 13.5,
                        color: const Color(0xff384250),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (exercise.isLogged) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xffF0FBF6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffBEE8D4)),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 20, color: _done),
                    SizedBox(width: 8),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: _done,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isFuture) ...[
              const SizedBox(height: 12),
              CustomButton(
                onTap: () async {
                  Navigator.pop(context);
                  await onLogTap(context);
                },
                text: 'Edit Log',
                isOutline: true,
              ),
            ],
          ] else if (!isFuture)
            CustomButton(
              onTap: () async {
                Navigator.pop(context);
                await onLogTap(context);
              },
              text: 'Log Exercise',
              isOutline: false,
            ),
        ],
      ),
    );
  }
}
