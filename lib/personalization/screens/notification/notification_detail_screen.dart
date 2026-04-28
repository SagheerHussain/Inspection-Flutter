import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/services/notifications/notification_model.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../controllers/notification_controller.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = NotificationController.instance;

    // Set from arguments if provided
    if (Get.arguments is NotificationModel) {
      controller.selectedNotification.value = Get.arguments as NotificationModel;
    }
    final paramId = Get.parameters['id'];
    if (paramId != null && paramId.isNotEmpty) {
      controller.selectedNotificationId.value = paramId;
    } else {
      controller.selectedNotificationId.value = controller.selectedNotification.value.id;
    }

    // Initialize the controller data outside the build method
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.init());

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Notification'),
        showSkipButton: false,
        showActions: false,
        showBackArrow: true,
        leadingOnPressed: () {
          if (Get.previousRoute.isEmpty || Get.previousRoute == TRoutes.notification) {
             Get.back();
          } else {
             Get.offNamed(TRoutes.notification);
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final notification = controller.selectedNotification.value;

          return TRoundedContainer(
            backgroundColor: dark ? TColors.dark : TColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notification.type.isNotEmpty)
                  TRoundedContainer(
                    padding: const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.sm),
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    child: Text(
                      notification.type.toUpperCase().replaceAll('_', ' '), 
                      style: Theme.of(context).textTheme.labelMedium!.apply(color: const Color(0xFF6C63FF)),
                    ),
                  ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text('Title', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleLarge!.apply(color: dark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text('Date', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  notification.formattedDate,
                  style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.grey),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text('Message', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  notification.body, 
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Notification Click event (if route is in data)
                if (notification.data.containsKey('route') && 
                    notification.data['route']?.toString().isNotEmpty == true &&
                    notification.data['route'] != TRoutes.notification &&
                    notification.data['route'] != TRoutes.notificationDetails)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final route = notification.data['route'].toString();
                        final routeId = notification.data['routeId']?.toString() ?? '';
                        Get.toNamed(route, parameters: {'id': routeId});
                      },
                      label: const Text('View Details'),
                      icon: const Icon(Iconsax.arrow_right),
                    ),
                  ),
                const SizedBox(height: TSizes.spaceBtwSections),
              ],
            ),
          );
        }),
      ),
    );
  }
}
