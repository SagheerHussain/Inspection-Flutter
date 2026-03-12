import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

import '../../../data/services/api/api_service.dart';
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
  final currentPage =
      1.obs; // Kept for compatibility, though pagination is now local
  final hasMoreData = true.obs;
  final int pageLimit = 10; // Increased limit for better UX

  // Local pagination storage
  List<ScheduleModel> _allFilteredRecords = [];
  int _currentIndex = 0;

  @override
  void onInit() {
    fetchSchedules();
    super.onInit();
  }

  /// Fetch all schedules from API (one huge batch), filter locally,
  /// then paginate the display locally via loadMore.
  Future<void> fetchSchedules({bool loadMore = false}) async {
    try {
      // LOCAL PAGINATION (Load More)
      if (loadMore) {
        if (!hasMoreData.value || isLoadingMore.value) return;
        isLoadingMore.value = true;

        // Simulate a tiny delay for UX (optional) or just load instantly
        // Picking next batch from local list
        final nextBatch =
            _allFilteredRecords.skip(_currentIndex).take(pageLimit).toList();

        if (nextBatch.isNotEmpty) {
          schedules.addAll(nextBatch);
          _currentIndex += nextBatch.length;
        }

        if (_currentIndex >= _allFilteredRecords.length) {
          hasMoreData.value = false;
        }

        isLoadingMore.value = false;
        return;
      }

      // INITIAL LOAD: Fetch All from Server
      isLoading.value = true;
      schedules.clear();
      _allFilteredRecords.clear();
      _currentIndex = 0;
      hasMoreData.value = true;

      // Retrieve stored engineer number
      final engineerNumber =
          GetStorage().read('INSPECTION_ENGINEER_NUMBER') ?? '9090909090';

      List<ScheduleModel> allCombinedRecords = [];

      if (searchQuery.isNotEmpty) {
        // SEARCH MODE: Fetch all statuses to search across assigned data
        final statuses = [
          InspectionStatuses.scheduled,
          InspectionStatuses.running,
          InspectionStatuses.reScheduled,
          InspectionStatuses.reInspection,
          InspectionStatuses.inspected,
          InspectionStatuses.cancel,
        ];

        await Future.wait(
          statuses.map((status) async {
            try {
              final response = await ApiService.post(
                ApiConstants.inspectionEngineerSchedulesUrl,
                {
                  "inspectionStatus": status,
                  "inspectionEngineerNumber": engineerNumber,
                },
              );
              final List<dynamic> dataList = response['data'] ?? [];
              allCombinedRecords.addAll(
                dataList.map((json) => ScheduleModel.fromJson(json)),
              );
            } catch (e) {
              // debugPrint('❌ Search fetch error for $status: $e');
            }
          }),
        );

        final query = searchQuery.toLowerCase();
        _allFilteredRecords =
            allCombinedRecords.where((record) {
              final idMatch = record.appointmentId
                  .toString()
                  .toLowerCase()
                  .contains(query);
              final phoneMatch = record.customerContactNumber
                  .toString()
                  .toLowerCase()
                  .contains(query);
              final ownerMatch = record.ownerName
                  .toString()
                  .toLowerCase()
                  .contains(query);
              return idMatch || phoneMatch || ownerMatch;
            }).toList();
      } else if (statusFilter == 'Upcoming') {
        // UPCOMING MODE: Fetch strictly Scheduled status
        final upcomingStatuses = [InspectionStatuses.scheduled];

        await Future.wait(
          upcomingStatuses.map((status) async {
            try {
              final response = await ApiService.post(
                ApiConstants.inspectionEngineerSchedulesUrl,
                {
                  "inspectionStatus": status,
                  "inspectionEngineerNumber": engineerNumber,
                },
              );
              final List<dynamic> dataList = response['data'] ?? [];
              allCombinedRecords.addAll(
                dataList.map((json) => ScheduleModel.fromJson(json)),
              );
            } catch (e) {
              // debugPrint('❌ Upcoming fetch error for $status: $e');
            }
          }),
        );

        _allFilteredRecords =
            allCombinedRecords.where((record) {
              if (record.inspectionStatus.toLowerCase() == 'pending')
                return false;
              return true;
            }).toList();

        // Ensure they are sorted by date
        _allFilteredRecords.sort((a, b) {
          final aDt = a.inspectionDateTime ?? DateTime(2099);
          final bDt = b.inspectionDateTime ?? DateTime(2099);
          return aDt.compareTo(bDt);
        });
      } else {
        // STATUS MODE: Fetch single status (with fallback for Re- variants)
        final List<String> statusVariants = [statusFilter];
        if (statusFilter == InspectionStatuses.running) {
          // If viewing running inspections, also include scheduled and reinspection variants as requested
          statusVariants.add(InspectionStatuses.scheduled);
          statusVariants.add(InspectionStatuses.reInspection);
          statusVariants.add('Reinspection');
          statusVariants.add('Re-Inspected');
          statusVariants.add('Reinspected');
          statusVariants.add('Rescheduled');
        } else if (statusFilter == InspectionStatuses.reInspection) {
          statusVariants.add('Reinspection');
          statusVariants.add('Re-Inspected');
          statusVariants.add('Reinspected');
        } else if (statusFilter == InspectionStatuses.reScheduled) {
          statusVariants.add('Rescheduled');
        }

        await Future.wait(
          statusVariants.map((status) async {
            try {
              final response = await ApiService.post(
                ApiConstants.inspectionEngineerSchedulesUrl,
                {
                  "inspectionStatus": status,
                  "inspectionEngineerNumber": engineerNumber,
                },
              );
              final List<dynamic> dataList = response['data'] ?? [];
              allCombinedRecords.addAll(
                dataList.map((json) => ScheduleModel.fromJson(json)),
              );
            } catch (e) {
              // debugPrint('❌ Status fetch error for $status: $e');
            }
          }),
        );

        _allFilteredRecords =
            allCombinedRecords.where((record) {
              // Exclude 'Pending' unless specific requirement
              if (record.inspectionStatus.toLowerCase() == 'pending')
                return false;

              // Robust matching: compare normalized strings (lowercase, no hyphens)
              var normalizedRecordStatus = record.inspectionStatus
                  .toLowerCase()
                  .replaceAll('-', '');
              var normalizedFilterStatus = statusFilter
                  .toLowerCase()
                  .replaceAll('-', '');

              // Unified mapping for Re-Inspection variants
              if (normalizedRecordStatus == 'reinspected')
                normalizedRecordStatus = 'reinspection';
              if (normalizedFilterStatus == 'reinspected')
                normalizedFilterStatus = 'reinspection';

              // If filter is Running, we allow several segments
              if (statusFilter == InspectionStatuses.running) {
                return true; // We already fetched only the variants we want
              }

              return normalizedRecordStatus == normalizedFilterStatus;
            }).toList();
      }

      // Initial Display Batch
      final firstBatch = _allFilteredRecords.take(pageLimit).toList();
      schedules.assignAll(firstBatch);
      _currentIndex = firstBatch.length;

      if (_currentIndex >= _allFilteredRecords.length) {
        hasMoreData.value = false;
      }
    } catch (e) {
      // debugPrint('❌ Error fetching schedules: $e');
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
    if (statusFilter == InspectionStatuses.inspected) return 'Inspected';
    if (statusFilter == InspectionStatuses.cancel) return 'Canceled';
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
    if (statusFilter == InspectionStatuses.cancel) return 'canceled records';
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
        // We'd ideally fetch the updated record or update the model locally
        // For now, let's refresh the whole list to be safe and accurate
        await refreshSchedules();

        // Also refresh dashboard stats so the countdown timer updates immediately
        if (Get.isRegistered<DashboardStatsController>()) {
          Get.find<DashboardStatsController>().refresh();
        }
      }

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Inspection status updated to $status',
      );
    } catch (e) {
      // debugPrint('❌ Status Update Error: $e');
      TLoaders.errorSnackBar(title: 'Update Failed', message: e.toString());
      rethrow;
    }
  }
}
