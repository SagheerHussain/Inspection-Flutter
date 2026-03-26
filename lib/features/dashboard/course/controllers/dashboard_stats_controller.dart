import 'dart:async';

import 'package:flutter/material.dart';
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

  final isScheduledExpired = false.obs;
  final isReScheduledExpired = false.obs;

  Timer? _countdownTimer;
  DateTime? _nextScheduledTime; // Combined for main banner
  DateTime? _nextReScheduledTime; // Specific for quick link

  @override
  void onInit() {
    fetchAllRecords();
    super.onInit();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchAllRecords() async {
    try {
      isLoading.value = true;
      final userEmail = UserController.instance.user.value.email;

      // Use constants from InspectionStatuses
      final statuses = [
        InspectionStatuses.scheduled,
        InspectionStatuses.running,
        InspectionStatuses.reScheduled,
        InspectionStatuses.reInspection,
        'Reinspection', // Variant 1
        'Re-Inspected', // Variant 2 (from user database)
        'Reinspected', // Variant 3
        'Rescheduled', // Fallback for variant naming
        InspectionStatuses.inspected,
        InspectionStatuses.cancel,
      ];

      final Map<String, List<ScheduleModel>> results = {};

      // Fetch all statuses in parallel
      await Future.wait(
        statuses.map((status) async {
          try {
            final response = await ApiService.post(
              ApiConstants.inspectionEngineerSchedulesUrl,
              {
                "inspectionStatus": status,
                  "allocatedTo": userEmail,
              },
            );
            final List<dynamic> dataList = response['data'] ?? [];
            results[status] =
                dataList.map((json) => ScheduleModel.fromJson(json)).toList();
          } catch (e) {
            // debugPrint('❌ Error fetching $status: $e');
            results[status] = [];
          }
        }),
      );

      // Combine all records for general use (like finding next inspection)
      final List<ScheduleModel> combined = [];
      results.values.forEach((list) => combined.addAll(list));

      allRecords.assignAll(combined);

      // Build a local map for robust counting
      final Map<String, int> counts = {};
      for (var status in statuses) {
        var normalizedStatus = status.toLowerCase().replaceAll('-', '');

        // Map 'reinspected' variants to 'reinspection' key so they appear in the same card
        if (normalizedStatus == 'reinspected')
          normalizedStatus = 'reinspection';
        if (normalizedStatus == 'rescheduled')
          normalizedStatus = 'rescheduled'; // ensures consistency

        // Sum up counts for variants
        counts[normalizedStatus] =
            (counts[normalizedStatus] ?? 0) + (results[status]?.length ?? 0);
      }

      // Update individual counts (1:1 mapping as requested)
      scheduledCount.value = counts['scheduled'] ?? 0;
      runningCount.value = counts['running'] ?? 0;
      reScheduledCount.value = counts['rescheduled'] ?? 0;
      reInspectionCount.value = counts['reinspection'] ?? 0;
      inspectedCount.value = counts['inspected'] ?? 0;
      canceledCount.value = counts['cancel'] ?? 0;

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
    }

    _nextScheduledTime = nextSched;
    _nextReScheduledTime = nextReSched;

    hasScheduledCountdown.value =
        scheduledCount.value > 0 && _nextScheduledTime != null;
    hasReScheduledCountdown.value =
        reScheduledCount.value > 0 && _nextReScheduledTime != null;
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
