import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../utils/constants/inspection_statuses.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../course/controllers/dashboard_stats_controller.dart';
import '../../../../../schedules/screens/schedules_screen.dart';
import 'search.dart';

class DashboardBanners extends StatelessWidget {
  const DashboardBanners({super.key, required this.txtTheme});

  final TextTheme txtTheme;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final stats = DashboardStatsController.instance;

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1st Banner: Schedules
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (Get.isRegistered<DashboardSearchController>()) {
                  Get.find<DashboardSearchController>().clearSearch();
                }
                Get.to(() => const SchedulesScreen(statusFilter: 'Upcoming'));
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        dark
                            ? [const Color(0xFF0D1B2E), const Color(0xFF162D4A)]
                            : [
                              const Color(0xFFD6E8FA),
                              const Color(0xFFB8D4F0),
                            ],
                  ),
                  boxShadow: [],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top Row: Countdown (left) + Icon (right) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Countdown Timer Label
                        Expanded(
                          child: Obx(() {
                            if (!stats.hasScheduledCountdown.value) {
                              return const SizedBox.shrink();
                            }
                            return _BannerTimer(
                              time: stats.scheduledCountdownText.value,
                              dayLabel: stats.scheduledCountdownDayLabel.value,
                              isExpired: stats.isScheduledExpired.value,
                              dark: dark,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4A90D9,
                            ).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF4A90D9),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Center: Animated Counter
                    Center(
                      child: Obx(
                        () => _AnimatedCounter(
                          value: stats.scheduledCount.value,
                          style:
                              txtTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 48,
                                height: 1.0,
                                color: const Color(0xFF4A90D9),
                              ) ??
                              const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4A90D9),
                              ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Bottom: Title
                    Text(
                      "Schedules",
                      style: txtTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2nd Banner: Running
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (Get.isRegistered<DashboardSearchController>()) {
                  Get.find<DashboardSearchController>().clearSearch();
                }
                Get.to(
                  () => const SchedulesScreen(
                    statusFilter: InspectionStatuses.running,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        dark
                            ? [const Color(0xFF2A1510), const Color(0xFF3D2218)]
                            : [
                              const Color(0xFFFFE0CC),
                              const Color(0xFFFFCDB2),
                            ],
                  ),
                  boxShadow: [],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Icon (Top Right)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF6B35,
                          ).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.play_circle_filled_rounded,
                          color: Color(0xFFFF6B35),
                          size: 30,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Center: Animated Counter
                    Center(
                      child: Obx(
                        () => _AnimatedCounter(
                          value: stats.runningCount.value,
                          style:
                              txtTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 48,
                                height: 1.0,
                                color: const Color(0xFFFF6B35),
                              ) ??
                              const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF6B35),
                              ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Bottom: Title
                    Text(
                      "Running",
                      style: txtTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerTimer extends StatelessWidget {
  final String time;
  final String dayLabel;
  final bool isExpired;
  final bool dark;

  const _BannerTimer({
    required this.time,
    required this.dayLabel,
    required this.isExpired,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Label (e.g., TODAY, TOMORROW)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color:
                dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            dayLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // "Next Inspection in" Label
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time == 'OVERDUE' ? "Inspection" : "Next Inspection in",
              style: TextStyle(
                color: dark ? Colors.white70 : Colors.black87,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),

        // Timer Box
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isExpired
                      ? Colors.red.withValues(alpha: 0.9)
                      : (dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExpired)
                  const _PulseDot()
                else
                  const Icon(
                    Icons.access_time_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.red, blurRadius: 4, spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}

/// Animated counter that counts up from 0 to the target value
class _AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle style;

  const _AnimatedCounter({required this.value, required this.style});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text('${_animation.value.toInt()}', style: widget.style);
      },
    );
  }
}
