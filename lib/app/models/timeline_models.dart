import 'package:flutter/material.dart';

/// Goal Journey Timeline domain classes - the plain, UI-facing shapes the
/// timeline widgets consume, kept separate from the raw JSON DTOs
/// (timeline_dto.dart) so the widgets never touch API field-naming details.

enum MilestoneType { daily, weekly, monthly, endGoal }

enum MilestoneStatus { completed, missed, active, upcoming }

/// Key into this map is the backend's `icon` string (see
/// docwellness-backend/utils/seedGoalTimeline.js's DEFAULT_DAILY_TASKS and
/// controllers/dietician/timelineController.js's custom-milestone tasks).
const Map<String, IconData> goalTaskIconMap = {
  'morning_drink': Icons.local_cafe,
  'breakfast': Icons.free_breakfast,
  'brunch': Icons.brunch_dining,
  'lunch': Icons.lunch_dining,
  'evening_snack': Icons.cookie,
  'dinner': Icons.dinner_dining,
  'night_drink': Icons.nightlight_round,
  'supplements': Icons.medication,
  // Legacy/custom-milestone icons (dietician-authored custom tasks can still
  // use any of these - see controllers/dietician/timelineController.js's
  // createMilestone, which accepts a free-form icon string).
  'restaurant': Icons.restaurant_menu,
  'water_drop': Icons.water_drop,
  'walk': Icons.directions_walk,
  'sleep': Icons.bedtime,
  'weight': Icons.monitor_weight,
  'camera': Icons.camera_alt,
  'chat': Icons.chat_bubble,
};

class GoalTask {
  final String id;
  final String title;
  final String metric;
  final IconData icon;
  bool done;
  // True for a meal-linked task (Morning Drink...Night Drink) - its `done`
  // comes straight from the patient's real MealLog, not a manual check-in,
  // so the UI shows it read-only with the logged detail inline instead of
  // a tappable checkbox. Supplements is the one daily task that's still
  // false here (manually checked off).
  final bool linked;
  // e.g. "320 kcal" - only present when `linked && done`.
  final String? loggedNote;

  GoalTask({
    required this.id,
    required this.title,
    required this.metric,
    required this.icon,
    required this.done,
    this.linked = false,
    this.loggedNote,
  });
}

class Milestone {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final MilestoneType type;
  final MilestoneStatus status;
  final double adherence;
  final List<GoalTask> tasks;

  Milestone({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    required this.status,
    required this.adherence,
    required this.tasks,
  });

  bool get isFullyDone =>
      tasks.isNotEmpty && tasks.every((t) => t.done);
}
