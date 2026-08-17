import 'dart:async';
import 'dart:convert';

import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:docwellness/app/modules/home/services/water_service.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:docwellness/main.dart' as main_app;
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterController extends GetxController {
  final WaterService _waterService = WaterService();

  // --- Observables ---
  RxDouble currentIntake = 0.0.obs; // today's total in liters
  RxDouble dailyGoal = 2.5.obs; // goal in liters
  RxDouble stepSize = 0.25.obs; // increment/decrement step in liters
  RxBool isSyncing = false.obs;

  // Individual entries: [{amount: 250, time: "14:30", synced: false}]
  RxList<Map<String, dynamic>> todayEntries = <Map<String, dynamic>>[].obs;

  // History for chart (last 7 days): [{date, totalAmount, goal}]
  RxList<Map<String, dynamic>> history = <Map<String, dynamic>>[].obs;

  // The day currently shown on the Home screen's card - defaults to real
  // today, but the Home day-navigator (HomeController.selectedDate) can
  // move this to a past day. currentIntake/todayEntries above always stay
  // live/editable for real today only (that's what add/remove/sync/the 11PM
  // auto-summary all operate on); browsing to a different day instead shows
  // a read-only fetched total for that day via viewedIntake, so the water
  // card reflects whichever day the patient is actually looking at instead
  // of always freezing on today's figure.
  Rx<DateTime> viewedDate = DateTime.now().obs;
  RxDouble viewedIntake = 0.0.obs;
  RxBool isLoadingViewedDay = false.obs;

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get isViewingToday => _isSameDate(viewedDate.value, DateTime.now());

  // What the card should actually display - today's live, editable total
  // while viewing today, or the fetched read-only total for any other day.
  double get displayIntake => isViewingToday ? currentIntake.value : viewedIntake.value;
  String get displayIntakeFormatted => displayIntake.toStringAsFixed(2);
  double get displayProgressPercent => dailyGoal.value > 0
      ? (displayIntake / dailyGoal.value).clamp(0.0, 1.0)
      : 0.0;

  /// Called when the Home screen's day-navigator changes - fetches the
  /// selected day's water log if it isn't today (today already has live
  /// data loaded via fetchTodayFromBackend/local entries).
  Future<void> setViewedDate(DateTime date) async {
    viewedDate.value = date;
    if (isViewingToday) return;

    isLoadingViewedDay.value = true;
    try {
      final data = await _waterService.getToday(date: date);
      final serverData = data != null && data['success'] == true ? data['data'] : null;
      final totalMl = (serverData?['totalAmount'] as num?)?.toInt() ?? 0;
      // A stale response for a day the user has since navigated away from
      // must not clobber a newer one that arrived first.
      if (_isSameDate(viewedDate.value, date)) {
        viewedIntake.value = totalMl / 1000;
      }
    } catch (e) {
      debugPrint('⚠️ setViewedDate fetch error: $e');
    } finally {
      if (_isSameDate(viewedDate.value, date)) {
        isLoadingViewedDay.value = false;
      }
    }
  }

  // ==========================================
  // Editing a viewed (non-today) day - see Goal Journey's MilestoneSheet,
  // which lets a patient log water for an already-passed day, same as Log
  // Meal already allows (see DietController.sendLogMeal). Deliberately NOT
  // routed through currentIntake/todayEntries above: those are shared with
  // the Home card's own always-real-today display, so repointing them at
  // whatever day this sheet has open would make Home briefly show a past
  // day's total as if it were today's the moment this sheet opens - see
  // this class's own doc comment on currentIntake/todayEntries. Each add
  // here syncs immediately (no local offline queue/debounce, unlike
  // today's entries) since this is a single deliberate action taken while
  // already online in the app, not passive background accumulation.
  // ==========================================

  RxBool isAddingToViewedDay = false.obs;

  /// Appends one entry (stepSize) to whichever day setViewedDate last
  /// pointed at and syncs it to the backend right away. No-op while
  /// viewing today - use addWater() instead, which goes through the local-
  /// storage/debounced-sync pipeline every other "today" entry already
  /// does.
  Future<void> addWaterToViewedDay() async {
    if (isViewingToday) return;
    final date = viewedDate.value;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final amountMl = (stepSize.value * 1000).round();
    final now = DateTime.now();
    final entry = {
      'amount': amountMl,
      'time': DateFormat('HH:mm').format(now),
      'timestamp': now.toIso8601String(),
    };

    // Optimistic - the patient tapped "+", show it immediately rather than
    // waiting on the round trip.
    if (_isSameDate(viewedDate.value, date)) {
      viewedIntake.value += amountMl / 1000;
    }

    isAddingToViewedDay.value = true;
    try {
      final result = await _waterService.logWater(
        date: dateStr,
        entries: [entry],
        goal: (dailyGoal.value * 1000).round(),
      );
      if (result == null || result['success'] != true) {
        // Reconcile with the server's real total rather than leaving a
        // possibly-wrong optimistic number on screen.
        if (_isSameDate(viewedDate.value, date)) {
          viewedIntake.value -= amountMl / 1000;
        }
        showAppToast(
          Get.overlayContext!,
          message: 'Could not log water for that day. Please try again.',
          type: AppToastType.error,
        );
      } else if (Get.isRegistered<TimelineController>()) {
        // The Goal Journey milestone sheet's "x/4 tasks done" summary and
        // the timeline dot's completion status both read off this cached
        // data - without a refresh they'd keep showing this day as
        // water-incomplete until some unrelated trigger refetched it.
        Get.find<TimelineController>().load(silent: true);
      }
    } catch (e) {
      debugPrint('⚠️ addWaterToViewedDay error: $e');
      if (_isSameDate(viewedDate.value, date)) {
        viewedIntake.value -= amountMl / 1000;
      }
    } finally {
      isAddingToViewedDay.value = false;
    }
  }

  // --- Private ---
  Timer? _syncTimer;
  Worker? _syncDebounce;
  String _today = '';

  String? get _token => main_app.token;

  static const String _prefsKeyPrefix = 'water_log_';
  static const String _prefsGoalKey = 'water_goal';

  @override
  void onInit() {
    super.onInit();
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadFromLocal().then((_) {
      // After local load, merge with server data
      fetchTodayFromBackend();
    });
    _scheduleSyncTimer();
    // Catch up any previous day's entries that never made it to the
    // backend, then clean up old SharedPreferences entries (>2 days) - in
    // that order, so cleanup never deletes something still unsynced.
    _syncOrphanedDays().then((_) => cleanOldData());

    // Auto-sync shortly after intake changes, instead of only on "Sync now"
    // or the 11 PM timer - debounced so a burst of +/- taps (from either the
    // Home card or the Goal Journey sheet, both of which share this one
    // controller) collapses into a single request instead of one per tap.
    _syncDebounce = debounce<double>(
      currentIntake,
      (_) => syncToBackend(silent: true),
      time: const Duration(milliseconds: 900),
    );
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    _syncDebounce?.dispose();
    super.onClose();
  }

  // ==========================================
  // Local Storage
  // ==========================================

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();

    // Load goal
    dailyGoal.value = prefs.getDouble(_prefsGoalKey) ?? 2.5;

    // Load today's entries
    final stored = prefs.getString('$_prefsKeyPrefix$_today');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      todayEntries.value = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _recalcTotal();
    }

    debugPrint(
      '💧 Loaded water: ${currentIntake.value}L / ${dailyGoal.value}L, ${todayEntries.length} entries',
    );
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKeyPrefix$_today',
      jsonEncode(todayEntries.toList()),
    );
    await prefs.setDouble(_prefsGoalKey, dailyGoal.value);
  }

  void _recalcTotal() {
    double total = 0;
    for (final entry in todayEntries) {
      total += (entry['amount'] as num) / 1000; // ml to liters
    }
    currentIntake.value = total;
  }

  // ==========================================
  // Add / Remove Water
  // ==========================================

  void addWater() {
    final amountMl = (stepSize.value * 1000).round(); // liters to ml
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    todayEntries.add({
      'amount': amountMl,
      'time': timeStr,
      'timestamp': now.toIso8601String(),
      'synced': false,
    });

    _recalcTotal();
    _saveToLocal();
    Posthog().capture(
      eventName: 'water_intake_added',
      properties: {
        'amount_ml': amountMl,
        'total_intake_ml': (currentIntake.value * 1000).round(),
      },
    );
  }

  void removeWater() {
    if (todayEntries.isEmpty) return;

    // Remove the last entry
    todayEntries.removeLast();
    _recalcTotal();
    _saveToLocal();
  }

  void setGoal(double goalLiters) {
    dailyGoal.value = goalLiters;
    _saveToLocal();
  }

  // ==========================================
  // Sync to Backend
  // ==========================================

  /// Schedule a one-shot sync at 11 PM tonight
  void _scheduleSyncTimer() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 23, 0);
    if (now.isAfter(target)) {
      // Already past 11 PM today, schedule for tomorrow
      target = target.add(const Duration(days: 1));
    }
    final duration = target.difference(now);
    debugPrint(
      '💧 11 PM water sync scheduled in ${duration.inMinutes} minutes',
    );
    _syncTimer = Timer(duration, () {
      _autoSyncAndShareWithDoctor();
      // Reschedule for next day
      _scheduleSyncTimer();
    });
  }

  /// Auto-sync at 11 PM: sync to DB + send daily summary to doctor in chat
  Future<void> _autoSyncAndShareWithDoctor() async {
    debugPrint('🕐 11 PM auto-sync triggered');

    // First sync any unsynced entries to backend
    await syncToBackend();

    // Then send the full daily summary to doctor via chat
    _sendDailySummaryToDoctor();
  }

  /// Send a comprehensive daily water intake summary to the doctor in chat
  void _sendDailySummaryToDoctor() {
    try {
      if (!Get.isRegistered<SocketService>()) return;
      final socketService = Get.find<SocketService>();
      if (!socketService.isConnected.value) {
        debugPrint('⚠️ Socket not connected, cannot send daily water summary');
        return;
      }

      final totalMl = (currentIntake.value * 1000).round();
      final goalMl = (dailyGoal.value * 1000).round();
      final percentage = dailyGoal.value > 0
          ? ((currentIntake.value / dailyGoal.value) * 100).round()
          : 0;
      final entryCount = todayEntries.length;

      // Build summary message
      String status;
      if (percentage >= 100) {
        status = '✅ Goal achieved!';
      } else if (percentage >= 75) {
        status = '👍 Almost there!';
      } else if (percentage >= 50) {
        status = '💧 Halfway done';
      } else {
        status = '⚠️ Needs more water';
      }

      final summaryMessage =
          '📊 Daily Water Summary\n'
          '💧 Total: ${currentIntakeFormatted}L / ${goalFormatted}L ($percentage%)\n'
          '📝 Glasses: $entryCount entries today\n'
          '$status';

      socketService.sendMessageV1(
        conversationId: '', // auto-resolved by server
        receiverId: '', // patient → dietician auto-routed
        clientMessageId: 'water_daily_${DateTime.now().millisecondsSinceEpoch}',
        content: summaryMessage,
        type: 'water_intake',
        waterIntakeData: {
          'amount': totalMl,
          'goal': goalMl,
          'percentage': percentage,
          'entryCount': entryCount,
          'date': _today,
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'daily_auto_sync',
        },
      );
      debugPrint(
        '💬 Daily water summary sent to doctor: ${totalMl}ml / ${goalMl}ml ($percentage%)',
      );
    } catch (e) {
      debugPrint('⚠️ Failed to send daily water summary to chat: $e');
    }
  }

  /// Manually trigger sync (also called at 11 PM and by the debounced
  /// auto-sync in onInit). `silent` suppresses the result toast - the
  /// debounced auto-sync fires in the background after every tap and
  /// shouldn't pop a toast the patient never asked for; the "Sync now"
  /// button and 11 PM summary still want that feedback.
  Future<void> syncToBackend({bool silent = false}) async {
    if (_token == null || _token!.isEmpty) {
      debugPrint('💧 No token, skip water sync');
      return;
    }
    if (todayEntries.isEmpty) {
      debugPrint('💧 No entries to sync');
      return;
    }

    isSyncing.value = true;

    // Gather unsynced entries
    final unsyncedEntries = todayEntries
        .where((e) => e['synced'] != true)
        .map(
          (e) => {
            'amount': e['amount'],
            'time': e['time'],
            'timestamp': e['timestamp'],
          },
        )
        .toList();

    if (unsyncedEntries.isEmpty) {
      debugPrint('💧 All entries already synced');
      isSyncing.value = false;
      return;
    }

    // Calculate total ml being synced (for chat message)
    final syncedAmountMl = unsyncedEntries
        .fold<num>(0, (sum, e) => sum + (e['amount'] as num))
        .toInt();

    final result = await _waterService.logWater(
      date: _today,
      entries: unsyncedEntries,
      goal: (dailyGoal.value * 1000).round(),
    );

    debugPrint('💧 Sync result: $result');

    if (result != null && result['success'] == true) {
      // Mark all as synced
      for (int i = 0; i < todayEntries.length; i++) {
        todayEntries[i]['synced'] = true;
      }
      todayEntries.refresh();
      await _saveToLocal();
      debugPrint('✅ Water data synced to backend');

      // Send water intake message to chat so dietician can see it
      _emitWaterIntakeToChat(totalSyncedMl: syncedAmountMl);

      if (!silent) {
        showAppToast(
          Get.overlayContext!,
          message: '${unsyncedEntries.length} entries synced successfully',
          type: AppToastType.success,
        );
      }
    } else {
      debugPrint('❌ Water sync failed');
      if (!silent) {
        showAppToast(
          Get.overlayContext!,
          message: 'Could not sync water data. Please try again.',
          type: AppToastType.error,
        );
      }
    }

    isSyncing.value = false;
  }

  /// Fetch history from backend for chart
  Future<void> fetchHistory() async {
    if (_token == null || _token!.isEmpty) return;

    final data = await _waterService.getHistory(days: 7);

    if (data != null) {
      final historyList = data
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Today's unsynced local entries won't be in the backend yet.
      // Override today's bar with the current in-memory total (in ml)
      // so the chart always reflects what the user actually drank today.
      final todayLocalMl = (currentIntake.value * 1000).round();
      if (todayLocalMl > 0) {
        for (int i = 0; i < historyList.length; i++) {
          if (historyList[i]['date'] == _today) {
            historyList[i]['totalAmount'] = todayLocalMl;
            break;
          }
        }
      }

      history.value = historyList;
    }
  }

  /// Fetch today's data from backend (on app start, merge with local)
  Future<void> fetchTodayFromBackend() async {
    if (_token == null || _token!.isEmpty) return;

    try {
      final data = await _waterService.getToday();

      if (data != null && data['success'] == true) {
        final serverData = data['data'];
        if (serverData == null) return;

        final serverEntries = serverData['entries'] as List? ?? [];

        // Update goal from server if available
        if (serverData['goal'] != null) {
          final serverGoalLiters = (serverData['goal'] as num) / 1000;
          if (serverGoalLiters != dailyGoal.value) {
            dailyGoal.value = serverGoalLiters;
          }
        }

        // Merge server entries that we don't have locally
        for (final se in serverEntries) {
          final seAmount = (se['amount'] as num?)?.toInt() ?? 0;
          final seTime = se['time']?.toString() ?? '';
          if (seAmount == 0 || seTime.isEmpty) continue;

          final exists = todayEntries.any(
            (le) => le['time'] == seTime && le['amount'] == seAmount,
          );
          if (!exists) {
            todayEntries.add({
              'amount': seAmount,
              'time': seTime,
              'timestamp': se['timestamp'] ?? DateTime.now().toIso8601String(),
              'synced': true,
            });
          }
        }
        _recalcTotal();
        await _saveToLocal();
      }
    } catch (e) {
      debugPrint('⚠️ fetchTodayFromBackend error: $e');
    }
  }

  /// Push any previous day's still-unsynced entries to the backend.
  /// syncToBackend() only ever operates on `todayEntries` (the current
  /// calendar day's in-memory list) - if the app was closed/killed before
  /// that day's debounced/11PM sync fired, or a sync attempt failed
  /// silently (syncToBackend's auto-sync always runs with silent: true),
  /// those entries were never retried once the day rolled over, and
  /// cleanOldData() below would eventually delete them un-synced - meaning
  /// they'd never reach the backend at all, and a later day-navigator visit
  /// to that day (see setViewedDate) would show a total lower than what was
  /// actually logged. Runs for every stored day (not just the last 2), so
  /// nothing is lost before cleanOldData prunes anything.
  Future<void> _syncOrphanedDays() async {
    if (_token == null || _token!.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefsKeyPrefix) && k != '$_prefsKeyPrefix$_today')
        .toList();

    for (final key in keys) {
      final dateStr = key.replaceFirst(_prefsKeyPrefix, '');
      final stored = prefs.getString(key);
      if (stored == null) continue;

      List<dynamic> decoded;
      try {
        decoded = jsonDecode(stored);
      } catch (_) {
        continue;
      }
      final entries = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      final unsynced = entries.where((e) => e['synced'] != true).toList();
      if (unsynced.isEmpty) continue;

      final payload = unsynced
          .map((e) => {'amount': e['amount'], 'time': e['time'], 'timestamp': e['timestamp']})
          .toList();

      final result = await _waterService.logWater(
        date: dateStr,
        entries: payload,
        goal: (dailyGoal.value * 1000).round(),
      );

      if (result != null && result['success'] == true) {
        for (final e in entries) {
          e['synced'] = true;
        }
        await prefs.setString(key, jsonEncode(entries));
        debugPrint('💧 Synced orphaned day $dateStr (${unsynced.length} entries)');
      } else {
        debugPrint('❌ Failed to sync orphaned day $dateStr, will retry next launch');
      }
    }
  }

  /// Clean up old local data (keep only last 2 days)
  Future<void> cleanOldData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));

    for (final key in keys) {
      if (key.startsWith(_prefsKeyPrefix)) {
        final dateStr = key.replaceFirst(_prefsKeyPrefix, '');
        try {
          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          if (date.isBefore(twoDaysAgo)) {
            await prefs.remove(key);
            debugPrint('🗑️ Cleaned old water log: $dateStr');
          }
        } catch (_) {}
      }
    }
  }

  // ==========================================
  // Chat Integration
  // ==========================================

  /// Emit water intake as a chat message so the dietician sees it
  void _emitWaterIntakeToChat({required int totalSyncedMl}) {
    try {
      if (!Get.isRegistered<SocketService>()) return;
      final socketService = Get.find<SocketService>();
      if (!socketService.isConnected.value) return;

      final totalLiters = (currentIntake.value).toStringAsFixed(1);
      socketService.sendMessageV1(
        conversationId: '', // empty = server auto-resolves
        receiverId: '', // patient → dietician auto-routed by backend
        clientMessageId: 'water_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'Logged ${totalSyncedMl}ml water (total: ${totalLiters}L / ${goalFormatted}L)',
        type: 'water_intake',
        waterIntakeData: {
          'amount': totalSyncedMl,
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'manual',
        },
      );
      debugPrint('💬 Water intake sent to chat: ${totalSyncedMl}ml');
    } catch (e) {
      debugPrint('⚠️ Failed to emit water intake to chat: $e');
    }
  }

  // --- Computed ---
  double get progressPercent => dailyGoal.value > 0
      ? (currentIntake.value / dailyGoal.value).clamp(0.0, 1.0)
      : 0.0;

  String get currentIntakeFormatted => currentIntake.value.toStringAsFixed(2);
  String get goalFormatted => dailyGoal.value.toStringAsFixed(1);

  /// Sync unsynced entries then wipe all in-memory state.
  /// Call this during logout before clearing SharedPreferences.
  Future<void> syncAndClear() async {
    // Push any unsynced entries to backend first
    try {
      await syncToBackend();
    } catch (_) {}

    // Reset all in-memory state so the next user starts fresh
    todayEntries.clear();
    history.clear();
    currentIntake.value = 0.0;
    dailyGoal.value = 2.5;
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
