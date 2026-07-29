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

  GoalTask({
    required this.id,
    required this.title,
    required this.metric,
    required this.icon,
    required this.done,
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
