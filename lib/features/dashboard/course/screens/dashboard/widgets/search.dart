import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../../schedules/screens/schedules_screen.dart';

class DashboardSearchController extends GetxController {
  static DashboardSearchController get instance => Get.find();
  final searchController = TextEditingController();

  void clearSearch() {
    searchController.clear();
  }
}

class DashboardSearchBox extends StatelessWidget {
  const DashboardSearchBox({super.key, required this.txtTheme});

  final TextTheme txtTheme;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(DashboardSearchController());

    return Container(
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: "Search Appt ID, Phone, or Owner...",
          hintStyle: txtTheme.bodyMedium?.copyWith(
            color: Colors.grey.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.withValues(alpha: 0.8),
            size: 24,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          final query = value.trim();
          if (query.isNotEmpty) {
            // Clear search field as requested when navigating to results screen
            controller.clearSearch();
            Get.to(() => SchedulesScreen(searchQuery: query, statusFilter: 'GLOBAL'));
          }
        },
      ),
    );
  }
}
