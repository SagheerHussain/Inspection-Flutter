import 'package:inspection_app/common/widgets/drawer/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../personalization/controllers/user_controller.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../controllers/dashboard_stats_controller.dart';
import 'widgets/appbar.dart';
import 'widgets/banners.dart';
import 'widgets/search.dart';
import 'widgets/top_courses.dart';

class CoursesDashboard extends StatelessWidget {
  const CoursesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final dark = THelperFunctions.isDarkMode(context);
    // Initialize required controllers
    Get.put(DashboardStatsController());
    if (!Get.isRegistered<UserController>()) Get.put(UserController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const DashboardAppBar(),
        drawer: TDrawer(),
        body: RefreshIndicator(
          displacement: 110, // Positioned perfectly below the glass app bar
          backgroundColor: dark ? TColors.darkContainer : Colors.white,
          color: TColors.primary,
          strokeWidth: 3,
          onRefresh: () async {
            if (Get.isRegistered<DashboardSearchController>()) {
              Get.find<DashboardSearchController>().clearSearch();
            }
            final stats = DashboardStatsController.instance;
            await stats.refresh();
          },
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section with Custom Shape
                    TPrimaryHeaderContainer(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 35, // More space below search
                          top: 110, // More space from top
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting
                            Obx(
                              () => Text(
                                UserController.instance.user.value.userName.isNotEmpty
                                    ? "Hey, ${UserController.instance.user.value.userName}"
                                    : "Hey, User",
                                style: txtTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Welcome Back
                            Text(
                              "Welcome Back 👋",
                              style: txtTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Search Box inside header
                            DashboardSearchBox(txtTheme: txtTheme),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Stats Banners
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DashboardBanners(txtTheme: txtTheme),
                    ),

                    const SizedBox(height: 12),
                    DashboardTopCourses(txtTheme: txtTheme),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
