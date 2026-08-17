import 'package:flutter/material.dart';

/// Goal Journey Timeline domain classes - the plain, UI-facing shapes the
/// timeline widgets consume, kept separate from the raw JSON DTOs
/// (timeline_dto.dart) so the widgets never touch API field-naming details.

enum MilestoneType { daily, weekly, monthly, endGoal }

// 'partial' = a past day with at least one task done but not every task -
// see docwellness-backend's computeMilestoneStatus, which is the single
// source of truth for this classification (name must match its returned
// string exactly - see MilestoneDto.toDomain's MilestoneStatus.values
// lookup).
enum MilestoneStatus { completed, partial, missed, active, upcoming }

/// Key into this map is the backend's `icon` string (see
/// docwellness-backend/utils/seedGoalTimeline.js's DEFAULT_DAILY_TASKS and
/// controllers/dietician/timelineController.js's custom-milestone tasks).
const Map<String, IconData> goalTaskIconMap = {
  'morning_drink': Icons.local_cafe,
  'breakfast': Icons.free_breakfast,
  'brunch': Icons.brunch_dining,
  'lunch': Icons.rice_bowl,
  'evening_snack': Icons.eco,
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
  // True for a meal-linked task (Morning Drink...Night Drink) or the Water
  // Intake task - its `done` comes straight from the patient's real
  // MealLog/WaterLog, not a manual check-in, so the UI shows it read-only
  // with the logged detail inline instead of a tappable checkbox.
  // Supplements/Walk/Sleep are the daily tasks still manually checked off.
  final bool linked;
  // e.g. "320 kcal" (meal) or "1.3/2.5 L" (water) - present when linked.
  final String? loggedNote;
  // 0..1, only meaningful for the Water Intake task - a meal being logged
  // is discrete (done or not), but water intake is a running total toward
  // a goal, so it gets an actual fraction to render a progress bar with.
  final double? progress;

  GoalTask({
    required this.id,
    required this.title,
    required this.metric,
    required this.icon,
    required this.done,
    this.linked = false,
    this.loggedNote,
    this.progress,
  });
}

/// Titles the client rolls up into one "Log Meal" x/7 progress row instead
/// of showing 7 separate checklist rows - the real serving-times a
/// MealLog entry can actually be logged against (see docwellness-backend's
/// utils/seedGoalTimeline.js::MEAL_LINKED_TASK_TITLES). Supplements used to
/// be lumped in here too, but it's optional and has no log source of its
/// own, so it's pulled out into its own card instead (see
/// [supplementsTaskTitle] / [TaskGroups.supplementsTask]).
const Set<String> mealGroupTaskTitles = {
  'Morning Drink',
  'Breakfast',
  'Brunch',
  'Lunch',
  'Evening Snack',
  'Dinner',
  'Night Drink',
};

/// Progress-based (not a manual checkbox) task, backed by WaterLog - see
/// seedGoalTimeline.js::WATER_TASK_TITLE.
const String waterTaskTitle = 'Water Intake';

/// Optional, no-log-source task rendered as its own dashed-border card
/// below the rest of the day's tasks instead of counting toward Log Meal
/// or the conceptual "x/N tasks done" tally - see seedGoalTimeline.js's
/// DEFAULT_DAILY_TASKS.
const String supplementsTaskTitle = 'Supplements';

/// Splits a milestone's flat task list into the groups the UI renders
/// differently: the meal group (one aggregated progress row), the water
/// task (its own progress row), Supplements (its own optional card, not
/// counted toward completion), and everything else (Walk/Sleep/any
/// dietician-custom task, rendered as plain checkbox rows same as before).
class TaskGroups {
  final List<GoalTask> mealTasks;
  final GoalTask? waterTask;
  final GoalTask? supplementsTask;
  final List<GoalTask> otherTasks;

  TaskGroups({
    required this.mealTasks,
    required this.waterTask,
    required this.supplementsTask,
    required this.otherTasks,
  });

  int get mealDone => mealTasks.where((t) => t.done).length;
  int get mealTotal => mealTasks.length;
  bool get mealComplete => mealTotal > 0 && mealDone == mealTotal;

  /// Conceptual task count for a compact summary (e.g. "3/4 done"): Log
  /// Meal and Water Intake each count as one, regardless of how many
  /// underlying docs back them. Supplements is optional and deliberately
  /// excluded - it never counts toward this total or its done-count.
  int get conceptualDone =>
      (mealComplete ? 1 : 0) +
      (waterTask?.done == true ? 1 : 0) +
      otherTasks.where((t) => t.done).length;
  int get conceptualTotal =>
      (mealTotal > 0 ? 1 : 0) + (waterTask != null ? 1 : 0) + otherTasks.length;

  factory TaskGroups.from(List<GoalTask> tasks) {
    final meal = tasks.where((t) => mealGroupTaskTitles.contains(t.title)).toList();
    GoalTask? water;
    GoalTask? supplements;
    final others = <GoalTask>[];
    for (final t in tasks) {
      if (mealGroupTaskTitles.contains(t.title)) continue;
      if (t.title == waterTaskTitle) {
        water = t;
      } else if (t.title == supplementsTaskTitle) {
        supplements = t;
      } else {
        others.add(t);
      }
    }
    return TaskGroups(mealTasks: meal, waterTask: water, supplementsTask: supplements, otherTasks: others);
  }
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
