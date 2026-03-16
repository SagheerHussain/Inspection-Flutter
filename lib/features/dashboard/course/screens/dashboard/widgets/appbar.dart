import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../../../utils/constants/sizes.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: AppBar(
          elevation: 0,
          centerTitle: false,
          backgroundColor:
              dark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.6),
          automaticallyImplyLeading: false,
          leading: const SizedBox.shrink(),
          leadingWidth: 0,
          shape: Border(
            bottom: BorderSide(
              color:
                  dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          title: Text(
            "OTOBIX",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize:
                  (Theme.of(context).textTheme.headlineMedium?.fontSize ?? 24) *
                  1.20,
            ),
          ),
          actions: [
            // Notification Bell with Counter Badge
            IconButton(
              onPressed: () => _showNotificationsSheet(context),
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: dark ? Colors.white : TColors.dark,
                    size: 26,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: TColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: const Text(
                        '0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hamburger Menu Icon
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(
                Icons.menu_rounded,
                color: dark ? Colors.white : TColors.dark,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        "Notifications",
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : TColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: TSizes.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "0",
                          style: TextStyle(
                            color: TColors.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Notification Items
                Expanded(
                  child: Center(
                    child: Text(
                      "No new notifications found.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: dark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(55);
}
