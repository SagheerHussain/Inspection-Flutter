import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/constants/inspection_statuses.dart';
import '../../../utils/popups/loaders.dart';
import '../../car_details/screens/car_details_screen.dart';
import '../../inspection_form/screens/inspection_form_screen.dart';
import '../controllers/schedule_controller.dart';
import '../models/schedule_model.dart';
import '../../dashboard/course/screens/dashboard/coursesDashboard.dart';

class SchedulesScreen extends StatelessWidget {
  final String statusFilter;
  final String searchQuery;

  const SchedulesScreen({
    super.key,
    this.statusFilter = 'SCHEDULED',
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    // Use a unique tag so each status filter (or search) gets its own controller
    final tag =
        searchQuery.isNotEmpty ? 'search_results' : 'schedule_$statusFilter';
    final controller = Get.put(
      ScheduleController(statusFilter: statusFilter, searchQuery: searchQuery),
      tag: tag,
    );
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0A0E21) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.screenTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Obx(
              () => Text(
                '${controller.totalRecords.value} ${controller.screenSubtitle}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: dark ? TColors.secondary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => controller.refreshSchedules(),
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: TColors.primary),
                SizedBox(height: 16),
                Text(
                  'Loading records...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (controller.schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _emptyIcon(statusFilter),
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${controller.screenTitle.toLowerCase()} found',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pull down to refresh',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: TColors.primary,
          onRefresh: controller.refreshSchedules,
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                controller.fetchSchedules(loadMore: true);
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount:
                  controller.schedules.length +
                  (controller.hasMoreData.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.schedules.length) {
                  return Obx(
                    () =>
                        controller.isLoadingMore.value
                            ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: TColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  );
                }
                return _ScheduleCard(
                  schedule: controller.schedules[index],
                  dark: dark,
                  controller: controller,
                );
              },
            ),
          ),
        );
      }),
    );
  }

  IconData _emptyIcon(String status) {
    if (status == InspectionStatuses.running)
      return Icons.play_circle_outline_rounded;
    if (status == InspectionStatuses.reInspection)
      return Icons.replay_circle_filled_rounded;
    if (status == InspectionStatuses.inspected)
      return Icons.check_circle_outline_rounded;
    if (status == InspectionStatuses.cancel) return Icons.cancel_outlined;
    return Icons.calendar_today_rounded;
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final bool dark;
  final ScheduleController controller;

  const _ScheduleCard({
    required this.schedule,
    required this.dark,
    required this.controller,
  });

  Color _statusColor(String status) {
    final normalized = status.toLowerCase().replaceAll('-', '');
    if (status == InspectionStatuses.inspected ||
        status == 'Completed' ||
        status == 'Approved')
      return const Color(0xFF4CAF50);
    if (status == InspectionStatuses.running) return const Color(0xFFFF9800);
    if (status == InspectionStatuses.scheduled || normalized == 'scheduled')
      return const Color(0xFF2196F3);
    if (status == InspectionStatuses.reScheduled || normalized == 'rescheduled')
      return const Color(0xFF673AB7);
    if (status == InspectionStatuses.reInspection ||
        normalized == 'reinspection' ||
        normalized == 'reinspected')
      return const Color(0xFF00BFA5);
    if (status == InspectionStatuses.cancel) return const Color(0xFFF44336);
    return const Color(0xFF9E9E9E);
  }

  String _normalizedStatusLabel(String status) {
    final normalized = status.toLowerCase().replaceAll('-', '');
    if (normalized == 'reinspected' || normalized == 'reinspection')
      return 'Re-inspection';
    return status;
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFF44336);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Capitalize each word's first letter
  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(schedule.inspectionStatus);
    final priorityColor = _priorityColor(schedule.priority);
    final normalizedStatus = schedule.inspectionStatus.toLowerCase().replaceAll(
      '-',
      '',
    );
    final isFromReInspection =
        (normalizedStatus != 'reinspection' && normalizedStatus != 'reinspected') &&
        (schedule.appointmentSource.toLowerCase().contains('re-inspected') ||
         schedule.appointmentSource.toLowerCase().contains('re-inspection'));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1F36) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                dark
                    ? Colors.black.withValues(alpha: 0.4)
                    : const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          if (!dark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          // ═══════════════════════════════════════════════
          // ROW 1: Appointment ID · City · Status  (chip style)
          // ═══════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    dark
                        ? [
                          statusColor.withValues(alpha: 0.20),
                          statusColor.withValues(alpha: 0.08),
                        ]
                        : [
                          statusColor.withValues(alpha: 0.10),
                          statusColor.withValues(alpha: 0.04),
                        ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                // Appointment ID chip
                _headerChip(
                  icon: Icons.tag_rounded,
                  label: schedule.appointmentId,
                  bgColor:
                      dark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white,
                  iconColor: const Color(0xFF6366F1),
                  textStyle: txtTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: dark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),

                if (isFromReInspection)
                  _headerChip(
                    icon: Icons.replay_rounded,
                    label: 'RE-INSPECTION',
                    bgColor: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                    iconColor: const Color(0xFF00BFA5),
                    textStyle: txtTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00BFA5),
                      fontSize: 10,
                    ),
                  ),

                const Spacer(),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.25),
                        statusColor.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _normalizedStatusLabel(schedule.inspectionStatus),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════
          // CARD BODY
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ROW 2: Owner Name (Title Case) + Phone ──
                Row(
                  children: [
                    // Gradient avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          schedule.ownerName.isNotEmpty
                              ? schedule.ownerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleCase(schedule.ownerName),
                            style: txtTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.2,
                              color:
                                  dark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.phone_rounded,
                                  size: 11,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  schedule.customerContactNumber.isNotEmpty
                                      ? schedule.customerContactNumber
                                      : 'No phone number',
                                  style: txtTheme.bodySmall?.copyWith(
                                    color:
                                        dark
                                            ? Colors.grey.shade400
                                            : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        schedule.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── ROW 3: Make · Model · Variant as chips + Reg plate ──
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (schedule.make.isNotEmpty)
                      _vehicleChip(
                        icon: Icons.factory_rounded,
                        label: schedule.make,
                        color: const Color(0xFF6366F1),
                      ),
                    if (schedule.model.isNotEmpty)
                      _vehicleChip(
                        icon: Icons.directions_car_rounded,
                        label: schedule.model,
                        color: const Color(0xFF0EA5E9),
                      ),
                    if (schedule.variant.isNotEmpty)
                      _vehicleChip(
                        icon: Icons.tune_rounded,
                        label: schedule.variant,
                        color: const Color(0xFF8B5CF6),
                      ),
                    // Registration number as subtle inline label
                    if (schedule.carRegistrationNumber.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              dark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFE2E8F0),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 11,
                              color:
                                  dark
                                      ? Colors.grey.shade500
                                      : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              schedule.carRegistrationNumber,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color:
                                    dark
                                        ? Colors.grey.shade400
                                        : const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // City chip moved next to Registration number
                    if (schedule.city.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              dark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFE2E8F0),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_city_rounded,
                              size: 11,
                              color: const Color(0xFF0EA5E9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              schedule.city.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color:
                                    dark
                                        ? Colors.white70
                                        : const Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── ROW 4: Inspection Date & Time with countdown ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          dark
                              ? [
                                const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                const Color(0xFF6366F1).withValues(alpha: 0.06),
                              ]
                              : [
                                const Color(0xFF3B82F6).withValues(alpha: 0.06),
                                const Color(0xFF6366F1).withValues(alpha: 0.03),
                              ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(
                        0xFF3B82F6,
                      ).withValues(alpha: dark ? 0.15 : 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inspection Date & Time',
                              style: txtTheme.labelSmall?.copyWith(
                                color:
                                    dark
                                        ? Colors.grey.shade500
                                        : const Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              schedule.formattedInspectionDate,
                              style: txtTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF3B82F6),
                                fontSize: 14,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (schedule.inspectionDateTime != null) ...[
                              const SizedBox(height: 4),
                              _CountdownText(
                                targetDate: schedule.inspectionDateTime!,
                                style: txtTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── ROW 5: Map / Directions ──
                if (schedule.inspectionAddress.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openDirections(schedule.inspectionAddress),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              dark
                                  ? [
                                    const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.12),
                                    const Color(
                                      0xFF059669,
                                    ).withValues(alpha: 0.06),
                                  ]
                                  : [
                                    const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.06),
                                    const Color(
                                      0xFF059669,
                                    ).withValues(alpha: 0.03),
                                  ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: dark ? 0.15 : 0.12),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tap for directions',
                                  style: txtTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF10B981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  schedule.inspectionAddress,
                                  style: txtTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color:
                                        dark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.directions_rounded,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════
          // ROW 6: Bottom Action Bar
          // ═══════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  dark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color:
                      dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // ── Left Group: Workflow Actions ──
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildLeftActions(context, controller),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ── Right Group: Call & SMS ──
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildRightActions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable header chip for Top Row
  Widget _headerChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    TextStyle? textStyle,
    bool flexible = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          if (flexible)
            Flexible(
              child: Text(
                label,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(label, style: textStyle),
        ],
      ),
    );
  }

  /// Vehicle detail chip (Make / Model / Variant)
  Widget _vehicleChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Left-aligned workflow actions: Start/Resume, Re-Schedule, Cancel, Show Details, Notes
  List<Widget> _buildLeftActions(
    BuildContext context,
    ScheduleController controller,
  ) {
    final status = schedule.inspectionStatus;
    final List<Widget> items = [];

    final normalizedStatus = status.toLowerCase().replaceAll('-', '');

    final isScheduled = normalizedStatus == 'scheduled';
    final isRescheduled = normalizedStatus == 'rescheduled';
    final isRunning = normalizedStatus == 'running';
    final isReinspection =
        normalizedStatus == 'reinspection' || normalizedStatus == 'reinspected';

    if (isScheduled || isRescheduled || isRunning || isReinspection) {
      // Primary Action (Play / Resume)
      items.add(
        _actionIcon(
          icon:
              isRunning
                  ? Icons.play_arrow_rounded
                  : Icons.play_circle_filled_rounded,
          color: const Color(0xFF4CAF50),
          tooltip: isRunning ? 'Resume Inspection' : 'Start Inspection',
          onTap: () async {
            if (isScheduled || isRescheduled || isReinspection) {
              // Switch to Running via API as requested
              try {
                // Keep existing values as requested
                await controller.updateTelecallingStatus(
                  telecallingId: schedule.id,
                  status: InspectionStatuses.running,
                  dateTime: schedule.inspectionDateTime?.toIso8601String(),
                  remarks: schedule.remarks,
                );
              } catch (e) {
                // Error handled in controller
                return;
              }
            }

            Get.to(
              () => InspectionFormScreen(
                appointmentId: schedule.appointmentId,
                schedule: schedule,
              ),
            );
          },
        ),
      );
      items.add(const SizedBox(width: 12));

      if (isRunning) {
        // Revert to Scheduled
        items.add(
          _actionIcon(
            icon: Icons.settings_backup_restore_rounded,
            color: const Color(0xFF2196F3),
            tooltip: 'Revert to Scheduled',
            onTap: () => _showRevertDialog(context, controller),
          ),
        );
      } else {
        // Re-Schedule
        items.add(
          _actionIcon(
            icon: Icons.event_repeat_rounded,
            color: const Color(0xFFFF9800),
            tooltip: 'Re-Schedule',
            onTap: () => _showRescheduleFlow(context, controller),
          ),
        );
        items.add(const SizedBox(width: 12));

        // Cancel
        items.add(
          _actionIcon(
            icon: Icons.cancel_rounded,
            color: const Color(0xFFF44336),
            tooltip: 'Cancel',
            onTap: () => _showCancelDialog(context, controller),
          ),
        );
      }
    } else if (status == InspectionStatuses.inspected ||
        status == 'Completed' ||
        status == 'Approved') {
      // Show Details button
      items.add(
        InkWell(
          onTap:
              () => Get.to(
                () => CarDetailsScreen(appointmentId: schedule.appointmentId),
              ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                255,
                2,
                217,
                255,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(
                  255,
                  2,
                  217,
                  255,
                ).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.description_rounded,
                  size: 14,
                  color: Color.fromARGB(255, 2, 217, 255),
                ),
                const SizedBox(width: 6),
                Text(
                  'View Details',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color.fromARGB(255, 34, 34, 34),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Canceled → no workflow buttons

    // Notes (left group, after workflow actions)
    if (schedule.additionalNotes.isNotEmpty) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 12));
      items.add(
        _actionIcon(
          icon: Icons.sticky_note_2_outlined,
          color: const Color(0xFFFF9800),
          tooltip: 'Notes',
          onTap: () => _showNotesDialog(context, schedule.additionalNotes),
        ),
      );
    }

    return items;
  }

  /// Right-aligned communication actions: Call & SMS
  List<Widget> _buildRightActions() {
    final List<Widget> items = [];

    // Call
    if (schedule.customerContactNumber.isNotEmpty) {
      items.add(
        _actionIcon(
          icon: Icons.phone_outlined,
          color: const Color(0xFF4CAF50),
          tooltip: 'Call',
          onTap: () => _makeCall(schedule.customerContactNumber),
        ),
      );
      items.add(const SizedBox(width: 12));
    }

    // SMS
    items.add(
      _actionIcon(
        icon: Icons.sms_rounded,
        color: const Color(0xFF2196F3),
        tooltip: 'SMS',
        onTap: () async {
          if (schedule.customerContactNumber.isNotEmpty) {
            final uri = Uri.parse('sms:${schedule.customerContactNumber}');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          }
        },
      ),
    );

    return items;
  }

  void _showCancelDialog(BuildContext context, ScheduleController controller) {
    final reasonController = TextEditingController();
    final dark = THelperFunctions.isDarkMode(context);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_rounded, color: Colors.red),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Inspection',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Appointment ID: ${schedule.appointmentId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Reason for cancellation',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 4,
                style: TextStyle(color: dark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Tell us why you are canceling...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor:
                      dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Keep it',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (reasonController.text.trim().isEmpty) {
                          TLoaders.warningSnackBar(
                            title: 'Reason Required',
                            message: 'Please provide a reason for cancellation',
                          );
                          return;
                        }
                        Get.back();
                        try {
                          await controller.updateTelecallingStatus(
                            telecallingId: schedule.id,
                            status: InspectionStatuses.cancel,
                            remarks: reasonController.text.trim(),
                          );
                          // Redirect back to main dashboard
                          Get.offAll(() => const CoursesDashboard());
                        } catch (e) {
                          // Error handled in controller
                        }
                      },
                      child: const Text(
                        'Confirm Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRevertDialog(BuildContext context, ScheduleController controller) {
    final dark = THelperFunctions.isDarkMode(context);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_backup_restore_rounded,
                  color: Color(0xFF2196F3),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Confirm Revert',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to move this inspection to Schedule?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'No, Keep it',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();
                        try {
                          await controller.updateTelecallingStatus(
                            telecallingId: schedule.id,
                            status: InspectionStatuses.scheduled,
                            dateTime:
                                schedule.inspectionDateTime?.toIso8601String(),
                            remarks: 'Reverted from Running to Scheduled',
                          );
                          // Redirect back to main dashboard
                          Get.offAll(() => const CoursesDashboard());
                        } catch (e) {
                          // Error handled in controller
                        }
                      },
                      child: const Text(
                        'Yes, Revert',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRescheduleFlow(
    BuildContext context,
    ScheduleController controller,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF9800),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Convert to UTC before sending to API
    final String isoDate = selectedDateTime.toUtc().toIso8601String();

    if (!context.mounted) return;
    _showRescheduleReasonDialog(context, controller, isoDate);
  }

  void _showRescheduleReasonDialog(
    BuildContext context,
    ScheduleController controller,
    String isoDate,
  ) {
    final reasonController = TextEditingController();
    final dark = THelperFunctions.isDarkMode(context);
    final dt = DateTime.parse(isoDate).toLocal();
    final displayDate = '${dt.day} ${_getMonthName(dt.month)} ${dt.year}';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final displayTime = '${hour.toString().padLeft(2, '0')}:$minute $period';

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_repeat_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reschedule Lead',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'ID: ${schedule.appointmentId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      dark
                          ? Colors.orange.withValues(alpha: 0.05)
                          : Colors.orange.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'NEW INSPECTION TIME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time_filled_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reason for rescheduling',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 4,
                style: TextStyle(color: dark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter reason here...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor:
                      dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Get.back();
                        _showRescheduleFlow(context, controller);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Change Date',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (reasonController.text.trim().isEmpty) {
                          TLoaders.warningSnackBar(
                            title: 'Reason Required',
                            message: 'Please provide a reason for rescheduling',
                          );
                          return;
                        }
                        Get.back();
                        try {
                          await controller.updateTelecallingStatus(
                            telecallingId: schedule.id,
                            status: InspectionStatuses.reScheduled,
                            dateTime: isoDate,
                            remarks: reasonController.text.trim(),
                          );
                          // Redirect back to main dashboard
                          Get.offAll(() => const CoursesDashboard());
                        } catch (e) {
                          // Error handled in controller
                        }
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    TextTheme txtTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: txtTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: txtTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showNotesDialog(BuildContext context, String notes) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.sticky_note_2_outlined, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Text('Additional Notes'),
              ],
            ),
            content: Text(notes),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Opens Google Maps with directions FROM device's current location TO the inspection address
  Future<void> _openDirections(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    // Using Google Maps Directions API with origin=My+Location (uses device GPS)
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=My+Location&destination=$encodedAddress&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Makes a phone call to the given number
  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

class _CountdownText extends StatefulWidget {
  final DateTime targetDate;
  final TextStyle? style;

  const _CountdownText({required this.targetDate, this.style});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final diff = widget.targetDate.difference(now);

    if (diff.isNegative) {
      final newTimeString = "OVERDUE";
      if (newTimeString != _timeString) {
        if (mounted) {
          setState(() {
            _timeString = newTimeString;
          });
        }
      }
      _timer?.cancel();
    } else {
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      final seconds = diff.inSeconds.remainder(60);

      final h = hours.toString().padLeft(2, '0');
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');

      final newTimeString = "Starts in $h:$m:$s";
      if (newTimeString != _timeString) {
        if (mounted) {
          setState(() {
            _timeString = newTimeString;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeString.isEmpty) return const SizedBox.shrink();

    if (_timeString == 'OVERDUE') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Text(
          'OVERDUE',
          style: widget.style?.copyWith(
            color: Colors.red,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Text(_timeString, style: widget.style);
  }
}
