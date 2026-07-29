import 'dart:developer';

import 'package:docwellness/app/models/timeline_dto.dart';
import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:get/get.dart';

import '../services/timeline_service.dart';

enum TimelineUiState { initial, loading, success, error }

/// Owns the Goal Journey Timeline's data - shared between the compact
/// JourneyCard (Home/Progress) and the full GoalTimelineScreen, registered
/// permanent so both can read the same live state without re-fetching.
class TimelineController extends GetxController {
  final TimelineService _service = TimelineService();

  final Rx<GoalDto?> goal = Rx<GoalDto?>(null);
  final Rx<TimelineStats?> stats = Rx<TimelineStats?>(null);
  final RxList<Milestone> milestones = <Milestone>[].obs;
  final Rx<TimelineUiState> state = TimelineUiState.initial.obs;
  final RxString errorMessage = ''.obs;
  final RxnString focusMilestoneId = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();

    // Live updates when a check-in lands on another device, the dietician
    // edits the plan, or sends a nudge - see socket_service.dart's
    // onTimelineUpdated/onMilestoneAdded/onNudgeReceived streams.
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.onTimelineUpdated.listen((_) => load(silent: true));
      socket.onMilestoneAdded.listen((_) => load(silent: true));
      socket.onNudgeReceived.listen((data) {
        focusMilestoneId.value = data['milestoneId'] as String?;
        load(silent: true);
      });
    }
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) state.value = TimelineUiState.loading;
    final dto = await _service.getTimeline();
    if (dto == null) {
      if (!silent) {
        errorMessage.value = 'Could not load your journey.';
        state.value = TimelineUiState.error;
      }
      return;
    }
    goal.value = dto.goal;
    stats.value = dto.stats;
    milestones.assignAll(dto.milestones.map((e) => e.toDomain()));
    state.value = TimelineUiState.success;
  }

  /// Optimistic toggle - instant feedback, rollback on failure.
  Future<void> toggleTask(Milestone milestone, GoalTask task) async {
    final wasDone = task.done;
    task.done = !wasDone;
    milestones.refresh();

    final success = wasDone
        ? await _service.uncheckToday(task.id)
        : await _service.checkIn(taskId: task.id, milestoneId: milestone.id);

    if (!success) {
      task.done = wasDone;
      milestones.refresh();
      log('TimelineController.toggleTask: sync failed for task ${task.id}');
      return;
    }

    // Refresh header stats silently - streak/adherence tick up live without
    // a full-screen loading flicker.
    final freshStats = await _service.getSummary();
    if (freshStats != null) stats.value = freshStats;
  }
}
