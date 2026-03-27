import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

import '../../../data/services/api/api_service.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/inspection_statuses.dart';
import '../../../utils/popups/loaders.dart';
import '../models/schedule_model.dart';
import '../../dashboard/course/controllers/dashboard_stats_controller.dart';

class ScheduleController extends GetxController {
  static ScheduleController get instance => Get.find();

  final String statusFilter;
  final String searchQuery;

  ScheduleController({
    this.statusFilter = InspectionStatuses.scheduled,
    this.searchQuery = '',
  });

  final schedules = <ScheduleModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMoreData = true.obs;
  final totalRecords = 0.obs; // Total from API response
  final int pageLimit = 20;

  int _currentPage = 1;

  /// Update a specific schedule across all controller instances (tags).
  static void updateScheduleGlobally(
    String appointmentId, {
    String? make,
    String? model,
    String? variant,
  }) {
    final tags = [
      'schedule_Running',
      'schedule_Scheduled',
      'schedule_Re-Inspection',
      'schedule_Re-Scheduled',
      'schedule_Inspected',
      'schedule_Cancelled',
      'schedule_Upcoming',
      'search_results',
    ];

    for (final tag in tags) {
      if (Get.isRegistered<ScheduleController>(tag: tag)) {
        final controller = Get.find<ScheduleController>(tag: tag);
        final index = controller.schedules.indexWhere(
          (s) => s.appointmentId == appointmentId,
        );

        if (index != -1) {
          final updated = controller.schedules[index].copyWith(
            make: make,
            model: model,
            variant: variant,
          );
          controller.schedules[index] = updated;
          controller.schedules.refresh();
        }
      }
    }
  }

  @override
  void onInit() {
    fetchSchedules();
    super.onInit();
  }

  /// Fetch schedules with server-side pagination.
  /// On initial load: fetches page 1.
  /// On loadMore: fetches the next page.
  Future<void> fetchSchedules({bool loadMore = false}) async {
    try {
      // ── LOAD MORE (next page) ──
      if (loadMore) {
        if (!hasMoreData.value || isLoadingMore.value) return;
        isLoadingMore.value = true;
        _currentPage++;

        final userEmail = UserController.instance.user.value.email;

        if (searchQuery.isNotEmpty) {
          // Search mode: fetch next page for all statuses and merge
          await _fetchSearchPage(userEmail);
        } else if (statusFilter == 'Upcoming') {
          await _fetchPageForStatus('Scheduled', userEmail);
        } else {
          await _fetchPageForStatus(statusFilter, userEmail);
        }

        isLoadingMore.value = false;
        return;
      }

      // ── INITIAL LOAD (page 1) ──
      isLoading.value = true;
      schedules.clear();
      _currentPage = 1;
      hasMoreData.value = true;
      totalRecords.value = 0;

      final userEmail = UserController.instance.user.value.email;

      if (searchQuery.isNotEmpty) {
        await _fetchSearchPage(userEmail);
      } else if (statusFilter == 'Upcoming') {
        await _fetchPageForStatus('Scheduled', userEmail);
      } else {
        await _fetchPageForStatus(statusFilter, userEmail);
      }
    } catch (e) {
      if (!loadMore) {
        Get.snackbar(
          'Error',
          'Failed to load records: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Fetch a single page for a given status and append results.
  Future<void> _fetchPageForStatus(String status, String userEmail) async {
    try {
      final response = await ApiService.post(
        ApiConstants.inspectionEngineerSchedulesPaginatedUrl(
          limit: pageLimit,
          pageNumber: _currentPage,
        ),
        {
          "inspectionStatus": status,
          "allocatedTo": userEmail,
        },
      );

      // Use 'total' from API response
      final apiTotal = response['total'] ?? 0;
      totalRecords.value = apiTotal;

      final List<dynamic> dataList = response['data'] ?? [];
      final newRecords =
          dataList.map((json) => ScheduleModel.fromJson(json)).toList();

      schedules.addAll(newRecords);

      // Check if we've loaded all records
      if (schedules.length >= apiTotal || newRecords.isEmpty) {
        hasMoreData.value = false;
      }
    } catch (e) {
      hasMoreData.value = false;
    }
  }

  /// Search mode: fetch page for ALL statuses and filter by query.
  Future<void> _fetchSearchPage(String userEmail) async {
    final statuses = InspectionStatuses.all;
    int maxTotal = 0;

    final List<ScheduleModel> pageResults = [];

    await Future.wait(
      statuses.map((status) async {
        try {
          final response = await ApiService.post(
            ApiConstants.inspectionEngineerSchedulesPaginatedUrl(
              limit: pageLimit,
              pageNumber: _currentPage,
            ),
            {
              "inspectionStatus": status,
              "allocatedTo": userEmail,
            },
          );

          final apiTotal = response['total'] ?? 0;
          maxTotal += apiTotal as int;

          final List<dynamic> dataList = response['data'] ?? [];
          pageResults.addAll(
            dataList.map((json) => ScheduleModel.fromJson(json)),
          );
        } catch (_) {}
      }),
    );

    totalRecords.value = maxTotal;

    // Apply search filter
    final query = searchQuery.toLowerCase();
    final filtered = pageResults.where((record) {
      final idMatch =
          record.appointmentId.toLowerCase().contains(query);
      final phoneMatch =
          record.customerContactNumber.toLowerCase().contains(query);
      final ownerMatch =
          record.ownerName.toLowerCase().contains(query);
      return idMatch || phoneMatch || ownerMatch;
    }).toList();

    schedules.addAll(filtered);

    // For search, stop paginating if no new results came back
    if (pageResults.isEmpty) {
      hasMoreData.value = false;
    }
  }

  /// Refresh schedules
  Future<void> refreshSchedules() async {
    hasMoreData.value = true;
    await fetchSchedules();
  }

  /// Get display title based on status filter
  String get screenTitle {
    if (searchQuery.isNotEmpty) return 'Search Results';
    if (statusFilter == 'Upcoming' ||
        statusFilter == InspectionStatuses.scheduled)
      return 'Schedules';
    if (statusFilter == InspectionStatuses.running)
      return 'Running Inspections';
    if (statusFilter == InspectionStatuses.reInspection) return 'Re-Inspection';
    if (statusFilter == InspectionStatuses.reScheduled) return 'Re-Scheduled';
    if (statusFilter == InspectionStatuses.inspected) return 'Inspected';
    if (statusFilter == InspectionStatuses.cancel) return 'Cancelled';
    return 'Records';
  }

  /// Get subtitle
  String get screenSubtitle {
    if (searchQuery.isNotEmpty) return 'matches found';
    if (statusFilter == 'Upcoming' ||
        statusFilter == InspectionStatuses.scheduled)
      return 'inspection leads';
    if (statusFilter == InspectionStatuses.running) return 'active inspections';
    if (statusFilter == InspectionStatuses.reInspection)
      return 're-inspection records';
    if (statusFilter == InspectionStatuses.inspected)
      return 'completed inspections';
    if (statusFilter == InspectionStatuses.cancel) return 'cancelled records';
    return 'records';
  }

  /// Update telecalling status
  Future<void> updateTelecallingStatus({
    required String telecallingId,
    required String status,
    String? dateTime,
    String? remarks,
  }) async {
    try {
      final storage = GetStorage();
      final userId = storage.read('USER_ID')?.toString() ?? storage.read('user_id')?.toString() ?? '';
      final userRole = storage.read('USER_ROLE')?.toString() ?? 'Inspection Engineer';

      final Map<String, dynamic> body = {
        'telecallingId': telecallingId,
        'changedBy': userId,
        'source': userRole,
        'inspectionStatus': status,
        'remarks': remarks ?? '',
      };

      if (dateTime != null) {
        body['inspectionDateTime'] = dateTime;
      }

      await ApiService.put(ApiConstants.updateTelecallingUrl, body);

      // Update local item status for instant UI feedback
      final index = schedules.indexWhere((s) => s.id == telecallingId);
      if (index != -1) {
        await refreshSchedules();

        // Also refresh dashboard stats
        if (Get.isRegistered<DashboardStatsController>()) {
          Get.find<DashboardStatsController>().refresh();
        }
      }

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Inspection status updated to $status',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Update Failed', message: e.toString());
      rethrow;
    }
  }
}
