import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../../../routes/routes.dart';
import '../../../../../../personalization/controllers/notification_controller.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final notificationController = NotificationController.instance;

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
            Obx(() {
              final unreadCount = notificationController.unreadCount;
              return IconButton(
                onPressed: () => Get.toNamed(TRoutes.notification),
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: dark ? Colors.white : TColors.dark,
                      size: 26,
                    ),
                    if (unreadCount > 0)
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
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
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
              );
            }),

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

  @override
  Size get preferredSize => const Size.fromHeight(55);
}
