import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/offline/offline_sync_service.dart';

/// Animated sync-progress badge for an appointment card.
///
/// • Invisible when there is nothing to sync (syncPercent == -1) or 100%
/// • Shows an animated progress bar + percentage when uploads are pending
/// • Turns green with a checkmark when everything is synced at 100%
class SyncProgressBadge extends StatelessWidget {
  final String appointmentId;
  final bool dark;

  const SyncProgressBadge({
    super.key,
    required this.appointmentId,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Safe access — service might not be registered during hot reload
      OfflineSyncService? svc;
      try {
        svc = OfflineSyncService.instance;
      } catch (_) {
        return const SizedBox.shrink();
      }

      // Access the state map reactively so Obx tracks changes to this appointment
      svc.state.forEach((k, v) {}); // touches map to register Obx dependency
      final percent = svc.getSyncPercent(appointmentId);
      final isOnline = svc.isOnline;

      // Nothing to show – appointment has no tracked media
      if (percent < 0) return const SizedBox.shrink();

      final isSynced = percent >= 100;

      if (isSynced) {
        // ── Fully Synced ─────────────────────
        return _SyncedBadge(dark: dark);
      }

      // ── Pending Upload ─────────────────────
      return _PendingBadge(
        percent: percent,
        isOnline: isOnline,
        dark: dark,
      );
    });
  }
}

// ─── Synced Badge ────────────────────────────────────────────────────────────

class _SyncedBadge extends StatefulWidget {
  final bool dark;
  const _SyncedBadge({required this.dark});

  @override
  State<_SyncedBadge> createState() => _SyncedBadgeState();
}

class _SyncedBadgeState extends State<_SyncedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cloud_done_rounded, size: 12, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Synced',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Badge ────────────────────────────────────────────────────────────

class _PendingBadge extends StatefulWidget {
  final double percent;
  final bool isOnline;
  final bool dark;

  const _PendingBadge({
    required this.percent,
    required this.isOnline,
    required this.dark,
  });

  @override
  State<_PendingBadge> createState() => _PendingBadgeState();
}

class _PendingBadgeState extends State<_PendingBadge>
    with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _shimmer;
  late Animation<double> _pulse;
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    // Shimmer sweep
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmer = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear);

    // Pulse glow when uploading
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);

    // Animated progress bar fill
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.percent / 100,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl.forward();
  }

  @override
  void didUpdateWidget(_PendingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: widget.percent / 100,
      ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
      _progressCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = widget.isOnline && widget.percent < 100;
    final pct = widget.percent.clamp(0.0, 100.0).toInt();

    final Color barColor =
        isUploading ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);

    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            widget.dark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: barColor.withValues(alpha: widget.dark ? 0.25 : 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: barColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Row: Icon + Label + % ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Opacity(
                  opacity: isUploading ? _pulse.value : 0.5,
                  child: Icon(
                    isUploading
                        ? Icons.cloud_upload_rounded
                        : Icons.wifi_off_rounded,
                    size: 11,
                    color: barColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isUploading ? 'Syncing' : 'Offline',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              // Percentage pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: barColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // ── Progress Bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Track
                Container(
                  height: 5,
                  width: 90,
                  decoration: BoxDecoration(
                    color: widget.dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                // Fill
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => Container(
                    height: 5,
                    width: 90 * _progressAnim.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUploading
                            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                            : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
                      ),
                    ),
                  ),
                ),
                // Shimmer overlay (only when online/uploading)
                if (isUploading)
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) {
                      final shimX = _shimmer.value * 90 - 30;
                      return Positioned(
                        left: shimX,
                        top: 0,
                        child: Container(
                          width: 30,
                          height: 5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.4),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
