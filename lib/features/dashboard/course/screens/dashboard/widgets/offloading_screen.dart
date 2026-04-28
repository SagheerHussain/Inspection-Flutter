import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../../../data/services/offline/inspection_offload_service.dart';

/// Screen showing all queued/syncing/done inspections from the offload queue.
/// Accessible by tapping the "Off-Loading" dashboard card.
class OffloadingScreen extends StatefulWidget {
  const OffloadingScreen({super.key});

  @override
  State<OffloadingScreen> createState() => _OffloadingScreenState();
}

class _OffloadingScreenState extends State<OffloadingScreen> {
  final RxBool isSelectionMode = false.obs;
  final RxList<String> selectedIds = <String>[].obs;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          dark ? const Color(0xFF0A0E21) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Off-Loading',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Obx(() {
              try {
                final svc = InspectionOffloadService.instance;
                final active = svc.queue.where((i) => i.isActive).length;
                final total = svc.queue.length;
                return Text(
                  active > 0
                      ? '$active syncing · $total total'
                      : 'All synced · $total inspections',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
        actions: [
          // ── Selection Mode Actions ──
          Obx(() {
            if (!isSelectionMode.value) {
              try {
                final svc = InspectionOffloadService.instance;
                if (svc.queue.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => _showClearConfirmation(context),
                  child: const Text(
                    'Clear List',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            } else {
              return Row(
                children: [
                  TextButton(
                    onPressed: () {
                      isSelectionMode.value = false;
                      selectedIds.clear();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    onPressed: selectedIds.isEmpty
                        ? null
                        : () => _deleteSelected(context),
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      color: selectedIds.isEmpty ? Colors.grey : Colors.red,
                    ),
                  ),
                ],
              );
            }
          }),

          // Overall progress indicator
          Obx(() {
            if (isSelectionMode.value) return const SizedBox.shrink();
            try {
              final svc = InspectionOffloadService.instance;
              final progress = svc.overallProgress;
              final isActive = svc.queue.any((i) => i.isActive);
              if (!isActive) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                    ),
                  ),
                ),
              );
            } catch (_) {
              return const SizedBox.shrink();
            }
          }),
        ],
      ),
      body: Obx(() {
        InspectionOffloadService? svc;
        try {
          svc = InspectionOffloadService.instance;
        } catch (_) {
          return const Center(child: Text('Service unavailable'));
        }

        if (svc.queue.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_done_rounded,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No inspections in queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submitted inspections will appear here\nwhile they sync to the cloud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: svc.queue.length,
          itemBuilder: (context, index) {
            // Show newest first
            final item = svc!.queue[svc.queue.length - 1 - index];
            return Obx(() => _OffloadItemCard(
                  item: item,
                  dark: dark,
                  isSelectionMode: isSelectionMode.value,
                  isSelected: selectedIds.contains(item.appointmentId),
                  onToggle: () {
                    if (selectedIds.contains(item.appointmentId)) {
                      selectedIds.remove(item.appointmentId);
                    } else {
                      selectedIds.add(item.appointmentId);
                    }
                  },
                ));
          },
        );
      }),
    );
  }

  void _deleteSelected(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${selectedIds.length} items?'),
        content: const Text('This will remove the selected items from the queue.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              InspectionOffloadService.instance.removeItems(selectedIds.toList());
              selectedIds.clear();
              isSelectionMode.value = false;
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear List Options',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Choose how you want to clear the off-loading queue.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              isSelectionMode.value = true;
            },
            child: const Text(
              'Select Items',
              style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(
            onPressed: () => _showFinalClearAllConfirmation(context),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalClearAllConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Clear All',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Are you sure you want to permanently remove all items from the queue? This cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              InspectionOffloadService.instance.clearQueue();
              Get.back(); // Close this confirmation dialog
              Get.back(); // Close the initial options dialog
            },
            child: const Text(
              'Yes, Clear All',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffloadItemCard extends StatelessWidget {
  final OffloadQueueItem item;
  final bool dark;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggle;

  const _OffloadItemCard({
    required this.item,
    required this.dark,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onToggle,
  });

  Color get _statusColor {
    switch (item.status) {
      case OffloadStatus.done:
        return const Color(0xFF4CAF50);
      case OffloadStatus.failed:
        return const Color(0xFFF44336);
      case OffloadStatus.uploading:
        return const Color(0xFF6C63FF);
      case OffloadStatus.pending:
        return const Color(0xFFF59E0B);
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case OffloadStatus.done:
        return 'Synced ✓';
      case OffloadStatus.failed:
        return 'Failed';
      case OffloadStatus.uploading:
        return 'Uploading...';
      case OffloadStatus.pending:
        return 'Pending';
    }
  }

  IconData get _statusIcon {
    switch (item.status) {
      case OffloadStatus.done:
        return Icons.check_circle_rounded;
      case OffloadStatus.failed:
        return Icons.error_rounded;
      case OffloadStatus.uploading:
        return Icons.sync_rounded;
      case OffloadStatus.pending:
        return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double percent = item.progressPercent;
    final bool isUploading = item.status == OffloadStatus.uploading;
    final bool isDone = item.status == OffloadStatus.done;
    final bool isFailed = item.status == OffloadStatus.failed;

    return GestureDetector(
      onTap: isSelectionMode ? onToggle : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected
              ? (dark ? const Color(0xFF20253D) : const Color(0xFFF0F2FF))
              : (dark ? const Color(0xFF141828) : Colors.white),
          boxShadow: [
            BoxShadow(
              color: _statusColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                : _statusColor.withValues(alpha: isDone ? 0.3 : 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: appointment ID + status ──
            Row(
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                    activeColor: const Color(0xFF6C63FF),
                    side: BorderSide(
                      color: dark ? Colors.white30 : Colors.black26,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.appointmentId,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: dark ? Colors.white70 : Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.ownerName} · ${item.make} ${item.model}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isUploading
                          ? _MiniSpinner(color: _statusColor)
                          : Icon(_statusIcon, size: 10, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Progress section ──
            Row(
              children: [
                Text(
                  isDone 
                      ? 'All required media synced'
                      : '${item.uploadedMedia}/${item.totalMedia} media uploaded',
                  style: TextStyle(
                    fontSize: 11,
                    color: dark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  isDone ? '100%' : '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    color: _statusColor.withValues(alpha: 0.1),
                  ),
                  LayoutBuilder(
                    builder: (ctx, constraints) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      height: 6,
                      width: constraints.maxWidth * (isDone ? 1.0 : percent),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDone
                              ? [Colors.green, Colors.greenAccent]
                              : isFailed
                                  ? [Colors.red, Colors.redAccent]
                                  : [
                                      const Color(0xFF6C63FF),
                                      const Color(0xFF9C8FFF),
                                    ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Error message if failed ──
            if (isFailed && item.error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.error!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isSelectionMode
                      ? onToggle
                      : () => InspectionOffloadService.instance.retryItem(
                            item.appointmentId,
                          ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],

            // ── Queued time ──
            const SizedBox(height: 8),
            Text(
              'Queued ${_timeAgo(item.queuedAt)}',
              style: TextStyle(
                fontSize: 10,
                color: dark ? Colors.white30 : Colors.black26,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MiniSpinner extends StatefulWidget {
  final Color color;
  const _MiniSpinner({required this.color});

  @override
  State<_MiniSpinner> createState() => _MiniSpinnerState();
}

class _MiniSpinnerState extends State<_MiniSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Icon(Icons.sync_rounded, size: 10, color: widget.color),
    );
  }
}
