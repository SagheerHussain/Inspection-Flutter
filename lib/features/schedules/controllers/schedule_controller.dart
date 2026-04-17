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
  final RxString searchQuery = ''.obs;

  ScheduleController({
    this.statusFilter = InspectionStatuses.scheduled,
    String? initialSearchQuery = '',
  }) {
    if (initialSearchQuery != null) {
      searchQuery.value = initialSearchQuery;
    }
  }

  final schedules = <ScheduleModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMoreData = true.obs;
  final totalRecords = 0.obs; // Total from API response
  final int pageLimit = 20;

  int _currentPage = 1;

  // ─── 🚀 HIGH-PERFORMANCE SEARCH CACHE ──────────────────────────
  static final List<ScheduleModel> _universalCache = [];
  static bool _cacheWarmed = false;
  static bool _cacheWarming = false;
  // ───────────────────────────────────────────────────────────────
  static void updateScheduleGlobally(
    String appointmentId, {
    String? make,
    String? model,
    String? variant,
    String? ownerName,
  }) {
    // Keep Search Cache synchronized with manual edits
    final cacheIdx = _universalCache.indexWhere((s) => s.appointmentId == appointmentId);
    if (cacheIdx != -1) {
      _universalCache[cacheIdx] = _universalCache[cacheIdx].copyWith(
        make: make, model: model, variant: variant, ownerName: ownerName,
      );
    }
    
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
            ownerName: ownerName,
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
  Future<void> fetchSchedules({bool loadMore = false, bool isRefresh = false}) async {
    try {
      // ── LOAD MORE (next page) ──
      if (loadMore) {
        if (!hasMoreData.value || isLoadingMore.value) return;
        isLoadingMore.value = true;
        _currentPage++;

        final userEmail = UserController.instance.user.value.email;

        if (searchQuery.isNotEmpty) {
          await _searchFromCache(userEmail);
        } else if (statusFilter == 'Upcoming') {
          await _fetchPageForStatus('Scheduled', userEmail);
        } else {
          await _fetchPageForStatus(statusFilter, userEmail);
        }

        isLoadingMore.value = false;
        return;
      }

      // ── INITIAL LOAD (page 1) ──
      if (!isRefresh) {
        isLoading.value = true;
      }
      _currentPage = 1;
      hasMoreData.value = true;
      // Do not clear schedules on refresh to avoid UI flicker
      if (!isRefresh) {
        schedules.clear();
        totalRecords.value = 0;
      }

      final userEmail = UserController.instance.user.value.email;

      if (searchQuery.isNotEmpty) {
        await _searchFromCache(userEmail);
      } else if (statusFilter == 'Upcoming') {
        await _fetchPageForStatus('Scheduled', userEmail, isRefresh: isRefresh);
      } else {
        await _fetchPageForStatus(statusFilter, userEmail, isRefresh: isRefresh);
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
  Future<void> _fetchPageForStatus(String status, String userEmail, {bool isGlobalSearch = false, bool isRefresh = false}) async {
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
          limit: pageLimit,
          pageNumber: _currentPage,
        ),
        body,
      );

      // Use 'total' from API response
      final apiTotal = response['total'] ?? 0;
      totalRecords.value = apiTotal;

      final List<dynamic> dataList = response['data'] ?? [];
      final List<ScheduleModel> newRecords =
          dataList.map((json) => ScheduleModel.fromJson(json)).toList();

      // Apply locally saved snapshots to ensure UI shows the latest manual updates
      _applyLocalSnapshots(newRecords);

      if (_currentPage == 1 && !isRefresh) {
        schedules.assignAll(newRecords);
      } else if (isRefresh) {
        schedules.assignAll(newRecords);
      } else {
        schedules.addAll(newRecords);
      }

      // Check if we've loaded all records
      if (schedules.length >= apiTotal || newRecords.isEmpty) {
        hasMoreData.value = false;
      }
    } catch (e) {
      hasMoreData.value = false;
    }
  }

  // ─── 🔥 BACKGROUND CACHE WARMER & IN-MEMORY SEARCH ──────────
  Future<void> _searchFromCache(String userEmail) async {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return;

    final cached = _filterCache(query);
    _applyLocalSnapshots(cached);
    schedules.assignAll(cached);
    totalRecords.value = cached.length;
    hasMoreData.value = false;

    if (!_cacheWarmed) {
      _warmUniversalCache(userEmail, onProgress: () {
        if (searchQuery.value.trim().toLowerCase() == query) {
          final fresh = _filterCache(query);
          _applyLocalSnapshots(fresh);
          schedules.assignAll(fresh);
          totalRecords.value = fresh.length;
        }
      });
    }
  }

  List<ScheduleModel> _filterCache(String q) {
    if (q.isEmpty) return _universalCache;
    
    // Split query by spaces to allow "Google-like" multi-part term matching
    final queryParts = q.toLowerCase().trim().split(RegExp(r'\s+'));
    final isExactIdSearch = q.contains('-');
    
    return _universalCache.where((r) {
      // 1. DEDICATED SEARCH FILTER
      if (statusFilter != 'GLOBAL' && statusFilter.isNotEmpty) {
        final currentFilter = statusFilter.trim().toLowerCase();
        final currentStatus = (r.inspectionStatus ?? '').trim().toLowerCase();
        
        if (currentFilter == 'upcoming') {
           if (currentStatus != 'scheduled') return false;
        } else {
           if (currentStatus != currentFilter) return false;
        }
      }

      // 2. EXACT APPOINTMENT ID MATCHING
      if (isExactIdSearch) {
        return r.appointmentId.toLowerCase().trim() == q.toLowerCase().trim();
      }

      // 3. TEXT FIELDS INDEX MATCHING (Simulated Compound Index)
      final indexString = [
        r.appointmentId,
        r.make,
        r.model,
        r.variant,
        r.customerContactNumber,
        r.city,
      ].join(' ').toLowerCase();

      // Ensure every word the user typed is found SOMEWHERE in the indexed dataset
      return queryParts.every((part) => indexString.contains(part));
    }).toList();
  }

  Future<void> _warmUniversalCache(String userEmail, {VoidCallback? onProgress}) async {
    if (_cacheWarming || _cacheWarmed) return;
    _cacheWarming = true;

    try {
      final user = UserController.instance.user.value;
      final body = <String, dynamic>{};
      if (user.id != 'superadmin') body['allocatedTo'] = userEmail;

      _universalCache.clear();
      final seen = <String>{};
      int limit = 200; // Safe chunk size that Kong proxy respects under 2s
      int currentPage = 1;
      int totalItems = 1;

      while (_universalCache.length < totalItems) {
        final response = await ApiService.post(
          ApiConstants.inspectionEngineerSchedulesPaginatedUrl(
            limit: limit,
            pageNumber: currentPage,
          ),
          body,
        );

        totalItems = response['total'] ?? 0;
        final List data = response['data'] ?? [];
        if (data.isEmpty) break;

        for (final json in data) {
          final model = ScheduleModel.fromJson(json);
          if (seen.add(model.appointmentId)) {
            _universalCache.add(model);
          }
        }
        
        // Let the UI progressively see results!
        onProgress?.call();
        currentPage++;
      }

      _cacheWarmed = true;
    } catch (e) {
      debugPrint('⚠️ [Cache] Failed: $e');
    } finally {
      _cacheWarming = false;
    }
  }

  /// Helper to overlay locally saved snapshots (manual edits) onto API results
  void _applyLocalSnapshots(List<ScheduleModel> records) {
    if (records.isEmpty) return;
    final storage = GetStorage();

    for (int i = 0; i < records.length; i++) {
      final snapshot = storage.read('snapshot_${records[i].appointmentId}');
      if (snapshot != null && snapshot is Map) {
        final make = snapshot['make']?.toString();
        final model = snapshot['model']?.toString();
        final variant = snapshot['variant']?.toString();
        final ownerName = snapshot['customerName']?.toString();

        records[i] = records[i].copyWith(
          make: (make != null && make.isNotEmpty) ? make : null,
          model: (model != null && model.isNotEmpty) ? model : null,
          variant: (variant != null && variant.isNotEmpty) ? variant : null,
          ownerName:
              (ownerName != null && ownerName.isNotEmpty) ? ownerName : null,
        );
      }
    }
  }

  /// Refresh schedules
  Future<void> refreshSchedules() async {
    _cacheWarmed = false;
    _cacheWarming = false;
    hasMoreData.value = true;
    await fetchSchedules(isRefresh: true);
  }

  /// Get display title based on status filter
  String get screenTitle {
    if (searchQuery.value.isNotEmpty) return 'Search Results';
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
    if (searchQuery.value.isNotEmpty) {
      return 'records found';
    }
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
