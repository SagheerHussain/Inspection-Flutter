import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:inspection_app/utils/constants/app_constants.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _inited = false;
  final _storage = GetStorage();

  /// 1) Init OneSignal with your App ID and ask for permission
  Future<void> init() async {
    if (_inited) return;

    OneSignal.initialize(AppConstants.oneSignalAppId); // start SDK
    await OneSignal.Notifications.requestPermission(true); // show OS prompt

    // When a notification arrives in foreground: just show it
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('🔔 OneSignal: Foreground Notification Received');
      debugPrint('   - Title: ${event.notification.title}');
      debugPrint('   - Body: ${event.notification.body}');
      debugPrint('   - Payload: ${event.notification.jsonRepresentation()}');

      // Only call this if you want to stop the default auto-display:
      event.preventDefault();

      // v5: display the SAME notification object
      event.notification.display();
    });

    // When the user taps a notification
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('🔔 OneSignal: Notification Clicked');
      debugPrint('   - Title: ${event.notification.title}');
      debugPrint('   - Payload: ${event.notification.jsonRepresentation()}');

      // Navigate to specific screen when notification is clicked
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        event.notification.additionalData ?? {},
      );

      // If your splash does async work, deferring avoids navigator race conditions:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('   - Additional Data: ${data.toString()}');
        // NotificationRouter.go(data);
      });
    });

    _inited = true;
  }

  /// 2) Link this device to YOUR user id (so server can target them)
  Future<void> login([String? mongoUserId]) async {
    // If not passed, retrieve the Mongo ID from local storage ('USER_ID')
    final userId = mongoUserId ?? _storage.read('USER_ID')?.toString();

    if (userId == null || userId.isEmpty) {
      debugPrint(
        '⚠️ NotificationService: mongoUserId is EMPTY or NULL — skipping OneSignal login!',
      );
      return;
    }

    // Build external ID like 'dev:mongodbId' or 'prod:mongodbId'
    final externalUserId = AppConstants.externalIdForNotifications(userId);

    debugPrint(
      '🔔 NotificationService: Setting OneSignal External ID to: $externalUserId',
    );

    await OneSignal.login(externalUserId);
    await OneSignal.User.addTagWithKey(
      "env",
      AppConstants.envName,
    ); // "dev"|"prod"

    debugPrint(
      '🔔 NotificationService: OneSignal Login Completed for $externalUserId',
    );
  }

  /// 3) unlink the device from the current user (call on sign-out)
  Future<void> logout() async {
    debugPrint('🔔 NotificationService: Logging out from OneSignal...');
    await OneSignal.logout();
  }
}
