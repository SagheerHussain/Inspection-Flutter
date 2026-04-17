import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../../../data/services/offline/inspection_offload_service.dart';
import 'offloading_screen.dart';

/// Animated dashboard card showing Off-Loading queue status.
/// Shows: active count, progress fraction, animated progress bar.
/// Tapping opens the Off-Loading detail screen.
class OffloadingDashboardCard extends StatelessWidget {
  const OffloadingDashboardCard({super.key, required this.txtTheme});

  final TextTheme txtTheme;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      InspectionOffloadService? svc;
      try {
        svc = InspectionOffloadService.instance;
      } catch (_) {
        return const SizedBox.shrink(); // Service not ready yet
      }

      final totalInQueue = svc.queue.where((i) => !i.isDone).length;
      final doneCount = svc.queue.where((i) => i.isDone).length;
      final totalEver = svc.queue.length;
      final progress = svc.overallProgress;
      final isActive = totalInQueue > 0;
      final label = svc.progressLabel;

      // Don't show the card if queue is completely empty and nothing in history
      if (totalEver == 0) return const SizedBox.shrink();

      const baseColor = Color(0xFF6C63FF); // Deep purple-blue
      final gradientColors = dark
          ? [const Color(0xFF1A1640), const Color(0xFF251E5C)]
          : [const Color(0xFFEDE9FF), const Color(0xFFDDD6FF)];

      return GestureDetector(
        onTap: () => Get.to(() => const OffloadingScreen()),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Off-Loading',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: baseColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: isActive
                        ? _SpinningIcon(color: baseColor)
                        : const Icon(
                            Icons.cloud_done_rounded,
                            color: baseColor,
                            size: 18,
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Fraction counter "1/3" ───────────────────────────────────
              Text(
                label,
                style: txtTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: dark ? Colors.white : const Color(0xFF1E0B6A),
                  fontSize: 30,
                  height: 1.0,
                ),
              ),

              const SizedBox(height: 6),

              // ── Status pill ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? baseColor.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) _PulsingDot(color: baseColor),
                    if (!isActive)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 8,
                        color: Colors.green,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      isActive
                          ? '${(progress * 100).toInt()}% synced'
                          : 'All synced',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isActive ? baseColor : Colors.green,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Progress bar ─────────────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          height: 5,
                          width: constraints.maxWidth,
                          color: baseColor.withValues(alpha: 0.12),
                        ),
                        // Fill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          height: 5,
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isActive
                                  ? [baseColor, const Color(0xFF4CAF50)]
                                  : [Colors.green, Colors.greenAccent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 2),
              Text(
                'Off-Loading',
                style: txtTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Spinning upload icon ───────────────────────────────────────────────────
class _SpinningIcon extends StatefulWidget {
  final Color color;
  const _SpinningIcon({required this.color});

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
      child: Icon(Icons.sync_rounded, color: widget.color, size: 18),
    );
  }
}

// ─── Pulsing dot for active state ──────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
