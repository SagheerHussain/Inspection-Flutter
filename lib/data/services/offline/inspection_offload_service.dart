import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../api/api_service.dart';
import '../../../utils/constants/api_constants.dart';
import 'offline_sync_service.dart';

// ─── Status Enum ───────────────────────────────────────────────────────────
enum OffloadStatus { pending, uploading, done, failed }

// ─── Queue Item Model ───────────────────────────────────────────────────────
class OffloadQueueItem {
  final String appointmentId;
  final String ownerName;
  final String make;
  final String model;
  final Map<String, dynamic> payload;       // Full API payload (URLs resolved)
  final Map<String, List<String>> imageFiles; // fieldKey → [localPaths]
  final String? carId;                      // non-null → UPDATE, null → ADD
  final String? telecallingId;
  final String? telecallingBody;            // JSON string for status update
  final bool isReInspection;
  final DateTime queuedAt;

  // Mutable sync state
  int totalMedia;
  int uploadedMedia;
  OffloadStatus status;
  String? error;

  // localPath → cloudinaryUrl (filled during upload)
  Map<String, String> resolvedUrls;

  OffloadQueueItem({
    required this.appointmentId,
    required this.ownerName,
    required this.make,
    required this.model,
    required this.payload,
    required this.imageFiles,
    this.carId,
    this.telecallingId,
    this.telecallingBody,
    this.isReInspection = false,
    DateTime? queuedAt,
    this.totalMedia = 0,
    this.uploadedMedia = 0,
    this.status = OffloadStatus.pending,
    this.error,
    Map<String, String>? resolvedUrls,
  })  : queuedAt = queuedAt ?? DateTime.now(),
        resolvedUrls = resolvedUrls ?? {};

  double get progressPercent =>
      totalMedia == 0 ? 1.0 : (uploadedMedia / totalMedia).clamp(0.0, 1.0);

  bool get isDone => status == OffloadStatus.done;
  bool get isFailed => status == OffloadStatus.failed;
  bool get isActive =>
      status == OffloadStatus.pending || status == OffloadStatus.uploading;

  Map<String, dynamic> toJson() => {
        'appointmentId': appointmentId,
        'ownerName': ownerName,
        'make': make,
        'model': model,
        'payload': payload,
        'imageFiles': imageFiles.map((k, v) => MapEntry(k, v)),
        'carId': carId,
        'telecallingId': telecallingId,
        'telecallingBody': telecallingBody,
        'isReInspection': isReInspection,
        'queuedAt': queuedAt.toIso8601String(),
        'totalMedia': totalMedia,
        'uploadedMedia': uploadedMedia,
        'status': status.name,
        'error': error,
        'resolvedUrls': resolvedUrls,
      };

  factory OffloadQueueItem.fromJson(Map<String, dynamic> j) =>
      OffloadQueueItem(
        appointmentId: j['appointmentId'] ?? '',
        ownerName: j['ownerName'] ?? '',
        make: j['make'] ?? '',
        model: j['model'] ?? '',
        payload: Map<String, dynamic>.from(j['payload'] ?? {}),
        imageFiles: (j['imageFiles'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, List<String>.from(v as List)),
        ),
        carId: j['carId'],
        telecallingId: j['telecallingId'],
        telecallingBody: j['telecallingBody'],
        isReInspection: j['isReInspection'] ?? false,
        queuedAt: DateTime.tryParse(j['queuedAt'] ?? '') ?? DateTime.now(),
        totalMedia: j['totalMedia'] ?? 0,
        uploadedMedia: j['uploadedMedia'] ?? 0,
        status: OffloadStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => OffloadStatus.pending,
        ),
        error: j['error'],
        resolvedUrls: Map<String, String>.from(j['resolvedUrls'] ?? {}),
      );
}

// ─── Service ───────────────────────────────────────────────────────────────
class InspectionOffloadService extends GetxService {
  static InspectionOffloadService get instance =>
      Get.find<InspectionOffloadService>();

  final RxList<OffloadQueueItem> queue = <OffloadQueueItem>[].obs;
  bool _isProcessing = false;
  final _storage = GetStorage();
  static const _queueKey = 'inspection_offload_queue';

  // ── Derived reactive state for dashboard ──
  int get activeCount => queue.where((i) => !i.isDone && !i.isFailed).length;
  int get totalCount => queue.length;
  int get doneCount => queue.where((i) => i.isDone).length;

  /// Total upload progress across all active and pending items (0.0–1.0)
  double get overallProgress {
    final incomplete = queue.where((i) => !i.isDone && !i.isFailed).toList();
    if (incomplete.isEmpty) {
      // If there are no incomplete items, but there are items in the queue,
      // it means everything is either done or failed. If done > 0, it's 100%.
      if (queue.any((i) => i.isDone)) return 1.0;
      return 0.0;
    }
    
    // We add 1 to totalMedia for the final API submit step to ensure progress doesn't stall at 99%.
    final totalSteps = incomplete.fold(0, (s, i) => s + i.totalMedia + 1);
    
    // Uploaded steps: uploadedMedia + (1 if submitting or done)
    final completedSteps = incomplete.fold(0, (s, i) {
      final submitProgress = i.isDone ? 1 : 0;
      return s + i.uploadedMedia + submitProgress;
    });

    if (totalSteps == 0) return 0.0;
    return (completedSteps / totalSteps).clamp(0.0, 1.0);
  }

  /// Human-readable progress label e.g. "1/3" (Inspections Offloaded / Total In Queue)
  String get progressLabel {
    final done = queue.where((i) => i.isDone).length;
    final total = queue.where((i) => !i.isFailed).length;
    if (total == 0) return '0/0';
    return '$done/$total';
  }

  @override
  void onInit() {
    super.onInit();
    _loadQueue();
    // Listen to connectivity via OfflineSyncService
    ever(OfflineSyncService.instance.isOnlineStream, (isOnline) {
      if (isOnline) {
        _processQueue();
      }
    });
    // If already online at start, kick off queue
    if (OfflineSyncService.instance.isOnline && queue.isNotEmpty) {
      _processQueue();
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Called from InspectionFormController on submit.
  /// Adds item to queue and starts processing in background.
  Future<void> enqueue(OffloadQueueItem item) async {
    // Count total media to upload (skipping already-resolved items)
    int count = 0;
    item.imageFiles.forEach((_, paths) {
      for (final p in paths) {
        if (!p.startsWith('http') && !item.resolvedUrls.containsKey(p)) {
          count++; // local file needs upload
        }
      }
    });
    item.totalMedia = count;

    queue.add(item);
    queue.refresh();
    _saveQueue();

    debugPrint(
      '📥 [Offload] Queued ${item.appointmentId} — $count media to upload',
    );

    // Kick off processing
    if (!_isProcessing) _processQueue();
  }

  /// Remove a failed item so it can be retried or discarded.
  void removeItem(String appointmentId) {
    queue.removeWhere((i) => i.appointmentId == appointmentId);
    queue.refresh();
    _saveQueue();
  }

  /// Retry a failed item.
  void retryItem(String appointmentId) {
    final idx = queue.indexWhere((i) => i.appointmentId == appointmentId);
    if (idx == -1) return;
    queue[idx].status = OffloadStatus.pending;
    queue[idx].error = null;
    queue.refresh();
    _saveQueue();
    _processQueue();
  }

  // ── Processing ──────────────────────────────────────────────────────────

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (true) {
        final pending = queue.firstWhereOrNull(
          (i) => i.status == OffloadStatus.pending,
        );
        if (pending == null) break;

        if (!OfflineSyncService.instance.isOnline) {
          debugPrint('📴 [Offload] Offline — pausing queue processing');
          break;
        }

        await _processItem(pending);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processItem(OffloadQueueItem item) async {
    final idx = queue.indexOf(item);
    if (idx == -1) return;

    debugPrint('🚀 [Offload] Processing ${item.appointmentId}...');
    queue[idx].status = OffloadStatus.uploading;
    queue.refresh();

    try {
      // ── Step 1: Upload all local media ──────────────────────────────────
      for (final entry in item.imageFiles.entries) {
        final fieldKey = entry.key;
        final paths = entry.value;

        for (final localPath in paths) {
          if (localPath.startsWith('http')) {
            // Already a URL — skip network upload
            item.resolvedUrls[localPath] = localPath;
            continue;
          }

          // Already uploaded in a previous session
          if (item.resolvedUrls.containsKey(localPath)) continue;

          final isVideo = localPath.endsWith('.mp4') ||
              localPath.endsWith('.mov') ||
              localPath.endsWith('.avi');

          final uploadUrl = isVideo
              ? ApiConstants.uploadVideoUrl
              : ApiConstants.uploadImagesUrl;
          final fileKey = isVideo ? 'video' : 'imagesList';

          try {
            final file = await http.MultipartFile.fromPath(fileKey, localPath);
            final response = await ApiService.multipartPost(
              url: uploadUrl,
              fields: {'appointmentId': item.appointmentId},
              files: [file],
            );

            final resultData = response['data'] ?? response;
            String? url;

            if (resultData['files'] is List &&
                (resultData['files'] as List).isNotEmpty) {
              url = resultData['files'][0]['url']?.toString();
            } else {
              url = (resultData['originalUrl'] ??
                      resultData['optimizedUrl'] ??
                      resultData['url'])
                  ?.toString();
            }

            if (url != null) {
              item.resolvedUrls[localPath] = url;
              item.uploadedMedia++;
              queue.refresh();
              _saveQueue();
              debugPrint(
                '✅ [Offload] Uploaded $fieldKey (${item.uploadedMedia}/${item.totalMedia})',
              );
            } else {
              throw Exception("Empty URL returned from Cloudinary API");
            }
          } catch (e) {
            debugPrint('⚠️ [Offload] Upload failed for $localPath: $e');
            // If it's a file finding error, it's unrecoverable. But fromPath typically throws if file is missing.
            if (e.toString().contains("No such file or directory") || e.toString().contains("Cannot open file")) {
               debugPrint('File physically missing: $localPath. Proceeding by dropping it.');
               item.totalMedia = (item.totalMedia - 1).clamp(0, 9999);
               queue.refresh();
               _saveQueue();
            } else {
               // A genuine network failure or API rejection -> abort entire sync for this item.
               throw Exception('Network or API Error uploading media: $e');
            }
          }
        }
      }

      // ── Step 2: Resolve URLs in payload ─────────────────────────────────
      final finalPayload = Map<String, dynamic>.from(item.payload);

      item.imageFiles.forEach((fieldKey, paths) {
        if (paths.isNotEmpty) {
          final urls = paths
              .map((p) => item.resolvedUrls[p] ?? p)
              .where((u) => u.startsWith('http'))
              .toList();
          if (urls.isNotEmpty) finalPayload[fieldKey] = urls;
        }
      });

      // Reconstruct composite arrays for backend schema compatibility
      List<String> getUrls(String key) {
        final urls = finalPayload[key];
        if (urls is List) return urls.map((e) => e.toString()).where((u) => u.startsWith('http')).toList();
        return [];
      }
      String getFirstUrl(String key) => getUrls(key).firstOrNull ?? '';

      finalPayload['airbagImages'] = [
        getFirstUrl('driverAirbagImages'),
        getFirstUrl('coDriverAirbagImages'),
        getFirstUrl('driverSeatAirbagImages'),
        getFirstUrl('coDriverSeatAirbagImages'),
        getFirstUrl('rhsCurtainAirbagImages'),
        getFirstUrl('lhsCurtainAirbagImages'),
        getFirstUrl('driverKneeAirbagImages'),
        getFirstUrl('coDriverKneeAirbagImages'),
        getFirstUrl('rhsRearSideAirbagImages'),
        getFirstUrl('lhsRearSideAirbagImages'),
      ];
      finalPayload['bonnetImages'] = [...getUrls('bonnetClosedImages'), ...getUrls('bonnetOpenImages')];
      finalPayload['frontBumperImages'] = [...getUrls('frontBumperLhs45DegreeImages'), ...getUrls('frontBumperRhs45DegreeImages'), ...getUrls('frontBumperImages')];
      finalPayload['rearBumperImages'] = [...getUrls('rearBumperLhs45DegreeImages'), ...getUrls('rearBumperRhs45DegreeImages'), ...getUrls('rearBumperImages')];
      finalPayload['lhsQuarterPanelImages'] = [getFirstUrl('lhsQuarterPanelWithRearDoorOpenImages'), getFirstUrl('lhsQuarterPanelWithRearDoorClosedImages')];
      finalPayload['rhsQuarterPanelImages'] = [getFirstUrl('rhsQuarterPanelWithRearDoorOpenImages'), getFirstUrl('rhsQuarterPanelWithRearDoorClosedImages')];
      finalPayload['apronLhsRhs'] = [...getUrls('lhsApronImages'), ...getUrls('rhsApronImages')];


      // ── Step 3: Submit to API ─────────────────────────────────────────
      Map<String, dynamic> response;
      if (item.carId != null) {
        // UPDATE existing record
        finalPayload['carId'] = item.carId;
        response = await ApiService.put(ApiConstants.carUpdateUrl, finalPayload);
      } else {
        // ADD new record
        finalPayload.remove('_id');
        finalPayload.remove('id');
        finalPayload.remove('objectId');
        response = await ApiService.post(
          ApiConstants.inspectionSubmitUrl,
          finalPayload,
        );
      }

      debugPrint('✅ [Offload] Inspection submitted: $response');

      // ── Step 4: Update telecalling status to Inspected ────────────────
      if (item.telecallingId != null && item.telecallingBody != null) {
        try {
          await ApiService.put(
            ApiConstants.updateTelecallingUrl,
            Map<String, dynamic>.from(
              Uri.splitQueryString(item.telecallingBody!),
            ),
          );
        } catch (e) {
          debugPrint('⚠️ [Offload] Telecalling update failed: $e');
        }
      }

      // ── Mark done ──────────────────────────────────────────────────────
      queue[idx].status = OffloadStatus.done;
      queue.refresh();
      _saveQueue();

      debugPrint('🎉 [Offload] ${item.appointmentId} fully synced!');

      // Refresh dashboard stats so item moves to "Inspected" count
      try {
        if (Get.isRegistered<dynamic>(tag: 'DashboardStatsController')) {
          // ignore DashboardStatsController refresh here — handled via offload done
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('❌ [Offload] Failed to process ${item.appointmentId}: $e');
      queue[idx].status = OffloadStatus.failed;
      queue[idx].error = e.toString();
      queue.refresh();
      _saveQueue();
    }
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  void _saveQueue() {
    try {
      _storage.write(_queueKey, queue.map((i) => i.toJson()).toList());
    } catch (e) {
      debugPrint('⚠️ [Offload] Failed to persist queue: $e');
    }
  }

  void _loadQueue() {
    try {
      final raw = _storage.read(_queueKey);
      if (raw == null) return;
      final list = (raw as List).cast<Map<String, dynamic>>();
      queue.assignAll(list.map(OffloadQueueItem.fromJson).toList());
      debugPrint('📦 [Offload] Restored ${queue.length} items from storage');
    } catch (e) {
      debugPrint('⚠️ [Offload] Failed to load queue: $e');
    }
  }
}
