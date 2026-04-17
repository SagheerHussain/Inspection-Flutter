import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../data/services/api/api_service.dart';
import '../../../../utils/constants/api_constants.dart';
import '../../../../utils/constants/inspection_statuses.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../schedules/models/schedule_model.dart';

/// Central controller that loads ALL records once and exposes
/// per-status counts for the dashboard cards.
/// Also provides a live countdown to the nearest upcoming inspection.
class DashboardStatsController extends GetxController {
  static DashboardStatsController get instance => Get.find();

  final isLoading = false.obs;
  final allRecords = <ScheduleModel>[].obs;

  // Counts by inspectionStatus
  final scheduledCount = 0.obs;
  final runningCount = 0.obs;
  final reInspectionCount = 0.obs;
  final reScheduledCount = 0.obs;
  final inspectedCount = 0.obs;
  final canceledCount = 0.obs;

  // ── Countdown states ──
  final scheduledCountdownText = ''.obs;
  final scheduledCountdownDayLabel = ''.obs;
  final hasScheduledCountdown = false.obs;

  final reScheduledCountdownText = ''.obs;
  final reScheduledCountdownDayLabel = ''.obs;
  final hasReScheduledCountdown = false.obs;

  final runningCountdownText = ''.obs;
  final runningCountdownDayLabel = ''.obs;
  final hasRunningCountdown = false.obs;

  final isScheduledExpired = false.obs;
  final isReScheduledExpired = false.obs;
  final isRunningExpired = false.obs;

  Timer? _countdownTimer;
  DateTime? _nextScheduledTime; // Combined for main banner
  DateTime? _nextReScheduledTime; // Specific for quick link
  DateTime? _nextRunningTime; // For running banner

  // ── Cache keys (GetStorage) ──
  static const _cacheKey = 'dashboard_counts_cache';
  final _storage = GetStorage();

  @override
  void onInit() {
    _restoreFromCache(); // ⚡ Instant — shows last known counts from disk immediately
    super.onInit();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  // ─── ⚡ Stale-While-Revalidate Cache ────────────────────────────────────────

  /// Instantly restore last known counts from disk — runs before any API call.
  /// This is why counts were 0 on first render: nothing was cached. After the
  /// first successful fetch, subsequent logins show real numbers immediately.
  void _restoreFromCache() {
    final raw = _storage.read(_cacheKey);
    if (raw == null || raw is! Map) return;

    scheduledCount.value   = raw['Scheduled']    ?? 0;
    runningCount.value     = raw['Running']       ?? 0;
    inspectedCount.value   = raw['Inspected']     ?? 0;
    canceledCount.value    = raw['Cancelled']     ?? 0;
    reScheduledCount.value = raw['Re-Scheduled']  ?? 0;
    reInspectionCount.value = raw['Re-Inspection'] ?? 0;

    debugPrint('⚡ [Dashboard] Restored counts from cache: Scheduled=${raw['Scheduled']}, '
        'Running=${raw['Running']}, Inspected=${raw['Inspected']}');
  }

  /// Write current counts to disk after a successful fetch.
  void _persistToCache() {
    _storage.write(_cacheKey, {
      'Scheduled':    scheduledCount.value,
      'Running':      runningCount.value,
      'Inspected':    inspectedCount.value,
      'Cancelled':    canceledCount.value,
      'Re-Scheduled': reScheduledCount.value,
      'Re-Inspection': reInspectionCount.value,
    });
  }

  /// Called by screenRedirect() after user is confirmed loaded.
  /// This is the guaranteed-safe point to fetch: UserController is ready,
  /// the user is authenticated, and we're about to open the dashboard.
  Future<void> kickStart() async {
    await fetchAllRecords();
  }
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> fetchAllRecords() async {
    try {
      isLoading.value = true;
      final userEmail = UserController.instance.user.value.email;

      // Core statuses to fetch
      final fetchStatuses = [
        'Scheduled',
        'Running',
        'Re-Scheduled',
        'Re-Inspection',
        'Inspected',
        'Cancelled',
      ];

      final Map<String, int> totals = {};
      final Map<String, List<ScheduleModel>> sampleRecords = {};

      // Fetch page 1 (limit=10) for each status — use 'total' for counts
      await Future.wait(
        fetchStatuses.map((status) async {
          try {
            final Map<String, dynamic> body = {
              "inspectionStatus": status,
            };

            final user = UserController.instance.user.value;
            if (user.id != 'superadmin') {
              body["allocatedTo"] = userEmail;
            }

            final response = await ApiService.post(
              ApiConstants.inspectionEngineerSchedulesPaginatedUrl(
                limit: 20,
                pageNumber: 1,
              ),
              body,
            );

            // Use the 'total' field from API response for accurate count
            totals[status] = response['total'] ?? 0;

            // Keep page 1 data for countdown timer logic
            final List<dynamic> dataList = response['data'] ?? [];
            sampleRecords[status] =
                dataList.map((json) => ScheduleModel.fromJson(json)).toList();
          } catch (e) {
            totals[status] = 0;
            sampleRecords[status] = [];
          }
        }),
      );

      // Combine sample records for countdown timer
      final List<ScheduleModel> combined = [];
      sampleRecords.values.forEach((list) => combined.addAll(list));
      allRecords.assignAll(combined);

      // Set dashboard card counts from API 'total' field
      scheduledCount.value = totals['Scheduled'] ?? 0;
      runningCount.value = totals['Running'] ?? 0;
      inspectedCount.value = totals['Inspected'] ?? 0;
      canceledCount.value = totals['Cancelled'] ?? 0;
      reScheduledCount.value = totals['Re-Scheduled'] ?? 0;
      reInspectionCount.value = totals['Re-Inspection'] ?? 0;

      // Persist fresh counts so next login shows real numbers instantly
      _persistToCache();

      _startCountdown();

    } catch (e) {
      // debugPrint('❌ Dashboard stats fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Countdown Logic ──

  void _startCountdown() {
    _countdownTimer?.cancel();
    _findNextInspections();

    _updateAllCountdownDisplays();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();

      // Every minute (or when current next one passes), re-scan records
      if (now.second == 0 ||
          (_nextScheduledTime != null && now.isAfter(_nextScheduledTime!))) {
        _findNextInspections();
      }
      _updateAllCountdownDisplays();
    });
  }

  void _findNextInspections() {
    final now = DateTime.now();
    DateTime? nextSched;
    DateTime? nextReSched;
    DateTime? nextRunning;

    // We only consider "Scheduled" for the main "Schedules" banner countdown
    final mainUpcomingStatuses = [InspectionStatuses.scheduled];

    for (final record in allRecords) {
      final dt = record.inspectionDateTime;
      if (dt == null) continue;

      // 1. Check for the main banner (Earliest upcoming OR most recent overdue)
      if (mainUpcomingStatuses.contains(record.inspectionStatus)) {
        if (nextSched == null || _isMoreUrgent(dt, nextSched, now)) {
          nextSched = dt;
        }
      }

      // 2. Check specifically for Re-Scheduled quick link
      if (record.inspectionStatus == InspectionStatuses.reScheduled) {
        if (nextReSched == null || _isMoreUrgent(dt, nextReSched, now)) {
          nextReSched = dt;
        }
      }

      // 3. Check for Running banner
      if (record.inspectionStatus == InspectionStatuses.running) {
        if (nextRunning == null || _isMoreUrgent(dt, nextRunning, now)) {
          nextRunning = dt;
        }
      }
    }

    _nextScheduledTime = nextSched;
    _nextReScheduledTime = nextReSched;
    _nextRunningTime = nextRunning;

    hasScheduledCountdown.value =
        scheduledCount.value > 0 && _nextScheduledTime != null;
    hasReScheduledCountdown.value =
        reScheduledCount.value > 0 && _nextReScheduledTime != null;
    hasRunningCountdown.value =
        runningCount.value > 0 && _nextRunningTime != null;
  }

  /// Helper to decide which date is "more urgent"
  /// Priority: Overdue ones (closest to now) > Future ones (closest to now)
  bool _isMoreUrgent(DateTime candidate, DateTime current, DateTime now) {
    final candidateIsPast = candidate.isBefore(now);
    final currentIsPast = current.isBefore(now);

    if (candidateIsPast && !currentIsPast)
      return true; // Overdue takes priority
    if (!candidateIsPast && currentIsPast) return false;

    if (candidateIsPast && currentIsPast) {
      return candidate.isAfter(
        current,
      ); // For overdue, pick the most recent one
    } else {
      return candidate.isBefore(current); // For future, pick the earliest one
    }
  }

  void _updateAllCountdownDisplays() {
    final now = DateTime.now();

    // Update Main Scheduled Banner
    if (_nextScheduledTime != null) {
      final diff = _nextScheduledTime!.difference(now);
      final isOverdue = diff.isNegative;

      isScheduledExpired.value = isOverdue || diff.inSeconds <= 3600;
      scheduledCountdownText.value =
          isOverdue ? 'OVERDUE' : _formatDuration(diff);
      scheduledCountdownDayLabel.value = _getDayLabel(_nextScheduledTime!);
    } else {
      scheduledCountdownText.value = '';
    }

    // Update Re-Scheduled Quick Link
    if (_nextReScheduledTime != null) {
      final diff = _nextReScheduledTime!.difference(now);
      final isOverdue = diff.isNegative;

      isReScheduledExpired.value = isOverdue || diff.inSeconds <= 3600;
      reScheduledCountdownText.value =
          isOverdue ? 'OVERDUE' : _formatDuration(diff);
      reScheduledCountdownDayLabel.value = _getDayLabel(_nextReScheduledTime!);
    } else {
      reScheduledCountdownText.value = '';
    }

    // Update Running Banner
    if (_nextRunningTime != null) {
      final diff = _nextRunningTime!.difference(now);
      final isOverdue = diff.isNegative;

      isRunningExpired.value = isOverdue || diff.inSeconds <= 3600;
      runningCountdownText.value =
          isOverdue ? 'OVERDUE' : _formatDuration(diff);
      runningCountdownDayLabel.value = _getDayLabel(_nextRunningTime!);
    } else {
      runningCountdownText.value = '';
    }
  }

  String _formatDuration(Duration diff) {
    if (diff.isNegative || diff == Duration.zero) {
      return '00h:00m:00s';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}h:${minutes.toString().padLeft(2, '0')}m:${seconds.toString().padLeft(2, '0')}s';
  }

  /// Returns "Today", "Tomorrow", or the weekday name.
  String _getDayLabel(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);
    final diff = targetDay.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[target.weekday - 1];
  }

  Future<void> refresh() async => await fetchAllRecords();
}
