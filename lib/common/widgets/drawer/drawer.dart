import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../personalization/controllers/theme_controller.dart';
import '../../../personalization/screens/profile/update_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../personalization/controllers/user_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../../features/dashboard/course/screens/dashboard/widgets/search.dart';

/// A reusable custom drawer widget with predefined settings for account details,
/// menu items, and a "Become a driver" section. The drawer's content is set
/// internally and does not require parameters when used.
class TDrawer extends StatelessWidget {
  /// Creates a [TDrawer] widget.
  const TDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = UserController.instance;
    final themeController = Get.put(ThemeController());
    final dark = THelperFunctions.isDarkMode(context);

    return Drawer(
      backgroundColor: dark ? TColors.dark : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 30),
            decoration: BoxDecoration(
              color: dark ? TColors.dark : TColors.cardBackgroundColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  userController.user.value.userName.isNotEmpty
                      ? userController.user.value.userName
                      : "User",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : TColors.textPrimary,
                  ),
                ),
                // Email
                Text(
                  userController.user.value.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        dark
                            ? Colors.white.withValues(alpha: 0.8)
                            : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Drawer menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Iconsax.user,
                  title: "My Profile",
                  onTap: () {
                    if (Get.isRegistered<DashboardSearchController>()) {
                      Get.find<DashboardSearchController>().clearSearch();
                    }
                    Navigator.pop(context); // Close drawer
                    Get.to(
                      () => const UpdateProfileScreen(),
                      transition: Transition.rightToLeftWithFade,
                    );
                  },
                ),

                const Divider(indent: 16, endIndent: 16),

                // Theme Toggle
                Obx(
                  () => ListTile(
                    leading: Icon(
                      themeController.isDark.value
                          ? Iconsax.sun_1
                          : Iconsax.moon,
                      color: dark ? TColors.primary : TColors.secondary,
                    ),
                    title: Text(
                      themeController.isDark.value ? "Light Mode" : "Dark Mode",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    trailing: Switch(
                      value: themeController.isDark.value,
                      onChanged: (value) => themeController.toggleTheme(),
                      activeColor: TColors.primary,
                    ),
                    onTap: () => themeController.toggleTheme(),
                  ),
                ),
              ],
            ),
          ),

          // Logout Button at the Bottom
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () => AuthenticationRepository.instance.logout(),
              icon: const Icon(Iconsax.logout, color: TColors.error),
              label: const Text(
                "Logout",
                style: TextStyle(
                  color: TColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// Helper method to build a drawer menu item.
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final dark = THelperFunctions.isDarkMode(context);
    return ListTile(
      leading: Icon(icon, color: dark ? Colors.white : TColors.dark),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      onTap: onTap,
    );
  }
}
