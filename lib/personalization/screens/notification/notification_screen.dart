import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../controllers/notification_controller.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../controllers/notification_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final controller = NotificationController.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.fetchNotifications(refresh: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        controller.fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Notifications'),
        showSkipButton: false,
        showBackArrow: true,
        showActions: true,
        actions: [
          Obx(() {
            if (controller.notifications.isEmpty || controller.unreadCount == 0) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: () => controller.markAllAsRead(),
              child: const Text('Mark All as Read', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            );
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Obx(() {
          if (controller.isLoading.value && controller.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (controller.notifications.isEmpty) {
            return const Center(child: Text('No new notifications found.'));
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchNotifications(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              itemCount: controller.notifications.length + (controller.isLoadMore.value ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: TSizes.spaceBtwItems),
              itemBuilder: (context, index) {
                if (index == controller.notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final notification = controller.notifications[index];
                final isRead = notification.isRead;
                
                return TRoundedContainer(
                  padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                  backgroundColor: isRead
                      ? (dark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05))
                      : (dark ? const Color(0xFF6C63FF).withValues(alpha: 0.15) : const Color(0xFF6C63FF).withValues(alpha: 0.1)),
                  child: ListTile(
                    leading: Icon(
                      Iconsax.notification_bing,
                      color: isRead ? Colors.grey : const Color(0xFF6C63FF),
                    ),
                    title: Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium!.apply(
                            color: dark ? Colors.white : Colors.black,
                            fontWeightDelta: isRead ? 0 : 2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: dark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.formattedDate,
                          style: Theme.of(context).textTheme.labelMedium!.apply(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: isRead
                        ? const Icon(Icons.check, color: Colors.green, size: 18)
                        : const Icon(CupertinoIcons.circle_filled, color: Color(0xFF6C63FF), size: 12),
                    onTap: () {
                      controller.selectedNotification.value = notification;
                      controller.selectedNotificationId.value = notification.id;
                      if (!isRead) {
                        controller.markNotificationAsViewed(notification);
                      }
                      Get.toNamed(TRoutes.notificationDetails, arguments: notification);
                    },
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
