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
            child: _BannerCard(
              title: "Schedules",
              count: stats.scheduledCount,
              hasCountdown: stats.hasScheduledCountdown,
              countdownText: stats.scheduledCountdownText,
              dayLabel: stats.scheduledCountdownDayLabel,
              isExpired: stats.isScheduledExpired,
              icon: Icons.calendar_month_rounded,
              baseColor: const Color(0xFF4A90D9),
              darkColors: [const Color(0xFF0D1B2E), const Color(0xFF162D4A)],
              lightColors: [const Color(0xFFD6E8FA), const Color(0xFFB8D4F0)],
              dark: dark,
              onTap: () {
                if (Get.isRegistered<DashboardSearchController>()) {
                  Get.find<DashboardSearchController>().clearSearch();
                }
                Get.to(() => const SchedulesScreen(statusFilter: 'Upcoming'));
              },
            ),
          ),
          const SizedBox(width: 12),

          // 2nd Banner: Running
          Expanded(
            child: _BannerCard(
              title: "Running",
              count: stats.runningCount,
              hasCountdown: stats.hasRunningCountdown,
              countdownText: stats.runningCountdownText,
              dayLabel: stats.runningCountdownDayLabel,
              isExpired: stats.isRunningExpired,
              icon: Icons.bolt_rounded,
              baseColor: const Color(0xFFFF7043),
              darkColors: [const Color(0xFF2C150D), const Color(0xFF3B1E13)],
              lightColors: [const Color(0xFFFBE9E7), const Color(0xFFFFCCBC)],
              dark: dark,
              onTap: () {
                if (Get.isRegistered<DashboardSearchController>()) {
                  Get.find<DashboardSearchController>().clearSearch();
                }
                Get.to(() => SchedulesScreen(statusFilter: InspectionStatuses.running));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String title;
  final RxInt count;
  final RxBool hasCountdown;
  final RxString countdownText;
  final RxString dayLabel;
  final RxBool isExpired;
  final IconData icon;
  final Color baseColor;
  final List<Color> darkColors;
  final List<Color> lightColors;
  final bool dark;
  final VoidCallback onTap;

  const _BannerCard({
    required this.title,
    required this.count,
    required this.hasCountdown,
    required this.countdownText,
    required this.dayLabel,
    required this.isExpired,
    required this.icon,
    required this.baseColor,
    required this.darkColors,
    required this.lightColors,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark ? darkColors : lightColors,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: dark ? 0.1 : 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header Row: Title + Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white70 : baseColor.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: baseColor, size: 18),
                ),
              ],
            ),
            
            const SizedBox(height: 8),

            // Countdown Area (Middle-top)
            Obx(() {
              if (!hasCountdown.value) return const SizedBox(height: 28);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired.value 
                    ? Colors.red.withValues(alpha: 0.1) 
                    : baseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dayLabel.value.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: isExpired.value ? Colors.red : (dark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        countdownText.value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isExpired.value ? Colors.red : (dark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Spacer(),

            // Large Hero Counter
            Obx(() => FittedBox(
              fit: BoxFit.scaleDown,
              child: _AnimatedCounter(
                value: count.value,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: dark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            )),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCounter oldWidget) {
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value.toDouble(),
        end: widget.value.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
      );
      _controller.reset();
      _controller.forward();
    }
    super.didUpdateWidget(oldWidget);
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
        return Text(_animation.value.toInt().toString(), style: widget.style);
      },
    );
  }
}
