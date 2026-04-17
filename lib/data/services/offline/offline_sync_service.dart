import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Tracks the offline-sync state for every appointment.
///
/// For each [appointmentId] it stores:
///   - totalMedia  : total local images/videos added
///   - uploadedMedia: count already successfully uploaded (cloudinary URL)
///
/// The derived [syncPercent] = uploadedMedia / totalMedia * 100.
/// 100 % means everything is synced (or nothing needs syncing).
class OfflineSyncService extends GetxService {
  static OfflineSyncService get instance => Get.find();

  // appointmentId → {total, uploaded}
  final RxMap<String, _SyncEntry> _state = <String, _SyncEntry>{}.obs;

  // Connectivity stream
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final _isOnline = false.obs;
  bool get isOnline => _isOnline.value;
  RxBool get isOnlineStream => _isOnline;

  // Persistent storage key
  static const _storageKey = 'offline_sync_state';
  final _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadPersistedState();
    _monitorConnectivity();
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  // ─── Connectivity ───────────────────────────────────────────

  void _monitorConnectivity() {
    // Set initial state
    Connectivity().checkConnectivity().then((results) {
      _isOnline.value = results.any((r) => r != ConnectivityResult.none);
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _isOnline.value = results.any((r) => r != ConnectivityResult.none);
    });
  }

  // ─── Reactive getters ───────────────────────────────────────

  /// Returns the sync percentage [0–100] for an appointmentId.
  /// Returns -1 if there is no tracked media for this appointment (nothing to sync).
  double getSyncPercent(String appointmentId) {
    final entry = _state[appointmentId];
    if (entry == null || entry.total == 0) return -1;
    return (entry.uploaded / entry.total * 100).clamp(0, 100);
  }

  /// Returns true if the appointment is fully synced (no pending local media).
  bool isSynced(String appointmentId) {
    final entry = _state[appointmentId];
    if (entry == null || entry.total == 0) return true;
    return entry.uploaded >= entry.total;
  }

  /// Rx notifier – rebuild downstream widgets when any appointment's state changes.
  RxMap<String, _SyncEntry> get state => _state;

  // ─── State Mutations ────────────────────────────────────────

  /// Call when the inspection form discovers N local media items for an appointment.
  /// [total] = all local paths (images + videos) currently tracked.
  /// [uploaded] = how many of those already have a cloudinary URL.
  void updateSyncState(
    String appointmentId, {
    required int total,
    required int uploaded,
  }) {
    final prev = _state[appointmentId];
    if (prev?.total == total && prev?.uploaded == uploaded) return;

    _state[appointmentId] = _SyncEntry(total: total, uploaded: uploaded);
    _state.refresh();
    _persistState();
  }

  /// Convenience: called when a single file finishes uploading.
  void markOneUploaded(String appointmentId) {
    final entry = _state[appointmentId];
    if (entry == null) return;
    final newUploaded = (entry.uploaded + 1).clamp(0, entry.total);
    _state[appointmentId] = _SyncEntry(
      total: entry.total,
      uploaded: newUploaded,
    );
    _state.refresh();
    _persistState();
  }

  /// Called when a new local file is registered (before upload).
  void addPendingItem(String appointmentId) {
    final entry = _state[appointmentId] ?? _SyncEntry(total: 0, uploaded: 0);
    _state[appointmentId] = _SyncEntry(
      total: entry.total + 1,
      uploaded: entry.uploaded,
    );
    _state.refresh();
    _persistState();
  }

  /// Clears state for an appointment (after successful full submission).
  void clearState(String appointmentId) {
    _state.remove(appointmentId);
    _state.refresh();
    _persistState();
  }

  // ─── Persistence ────────────────────────────────────────────

  void _persistState() {
    final map = <String, dynamic>{};
    _state.forEach((id, entry) {
      map[id] = {'total': entry.total, 'uploaded': entry.uploaded};
    });
    _storage.write(_storageKey, map);
  }

  void _loadPersistedState() {
    final raw = _storage.read(_storageKey);
    if (raw == null || raw is! Map) return;
    raw.forEach((key, value) {
      if (value is Map) {
        final total = value['total'] as int? ?? 0;
        final uploaded = value['uploaded'] as int? ?? 0;
        if (total > 0) {
          _state[key.toString()] = _SyncEntry(total: total, uploaded: uploaded);
        }
      }
    });
  }
}

class _SyncEntry {
  final int total;
  final int uploaded;

  const _SyncEntry({required this.total, required this.uploaded});
}
