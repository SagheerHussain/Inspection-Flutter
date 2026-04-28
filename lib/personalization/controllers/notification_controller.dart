import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/services/api/api_service.dart';
import '../../../data/services/notifications/notification_model.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/popups/loaders.dart';
import '../../data/repository/authentication_repository/authentication_repository.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.isRegistered() ? Get.find() : Get.put(NotificationController());

  final isLoading = false.obs;
  final isLoadMore = false.obs;
  final selectedNotification = NotificationModel.empty().obs;
  final selectedNotificationId = ''.obs;

  RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  
  int _currentPage = 1;
  final int _limit = 30;
  bool _hasMore = true;

  String get currentUserId {
    try {
      final id = AuthenticationRepository.instance.getUserID;
      if (id.isNotEmpty) return id;
    } catch (_) {}
    
    final storage = GetStorage();
    return storage.read('USER_ID')?.toString() ?? 
           storage.read('user_id')?.toString() ?? 
           storage.read('uid')?.toString() ?? 
           '';
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchNotifications();
    });
  }

  /// Init Data for details screen
  Future<void> init() async {
    try {
      if (selectedNotification.value.id.isEmpty) {
        if (selectedNotificationId.isEmpty) {
          Get.offNamed(TRoutes.notification);
        } else {
          // Find locally first
          final localNotification = notifications.firstWhereOrNull((n) => n.id == selectedNotificationId.value);
          if (localNotification != null) {
            selectedNotification.value = localNotification;
          } else {
            await fetchNotificationDetails(selectedNotificationId.value);
          }
        }
      }

      if (selectedNotification.value.id.isNotEmpty && !selectedNotification.value.isRead) {
        await markNotificationAsViewed(selectedNotification.value);
      }
    } catch (e) {
      if (kDebugMode) printError(info: e.toString());
      TLoaders.errorSnackBar(title: 'Oh Snap', message: 'Unable to fetch Notification details. Try again.');
    }
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (isLoading.value || isLoadMore.value) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        notifications.clear();
        isLoading.value = true;
      } else {
        if (!_hasMore) return;
        isLoadMore.value = true;
      }
    });

    try {
      final userId = currentUserId;
      if (userId.isEmpty) {
        if (kDebugMode) print('No user ID found for notifications');
        return;
      }

      final url = ApiConstants.notificationsListUrl(
        userId: userId,
        page: _currentPage,
        limit: _limit,
      );

      final response = await ApiService.get(url);
      
      if (kDebugMode) {
        print('====== NOTIFICATIONS API RESPONSE ======');
        print(response);
        print('========================================');
      }

      List<dynamic> items = [];
      if (response.containsKey('items') && response['items'] is List) {
        items = response['items'] as List;
      } else if (response.containsKey('data')) {
        final data = response['data'];
        if (data is Map && data['notifications'] != null) {
          items = data['notifications'] as List;
        } else if (data is List) {
          items = data;
        }
      }

      if (items.isEmpty) {
        _hasMore = false;
      } else {
        final newNotifications = items.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
        
        notifications.addAll(newNotifications);
        
        if (newNotifications.length < _limit) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
      }
    } catch (e) {
      TLoaders.warningSnackBar(title: "Error", message: "Failed to fetch notifications: $e");
    } finally {
      isLoading.value = false;
      isLoadMore.value = false;
    }
  }
  
  Future<void> fetchNotificationDetails(String notificationId) async {
    try {
      final userId = currentUserId;
      if (userId.isEmpty) return;

      final url = ApiConstants.notificationDetailsUrl(
        userId: userId,
        notificationId: notificationId,
      );

      final response = await ApiService.get(url);
      final data = response['data'];
      
      if (data != null) {
        selectedNotification.value = NotificationModel.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching notification details: $e');
    }
  }

  Future<void> markNotificationAsViewed(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final userId = currentUserId;
      if (userId.isEmpty) return;

      // Optimistic update
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        notifications[index].isRead = true;
        notifications.refresh();
      }
      
      if (selectedNotification.value.id == notification.id) {
        selectedNotification.value.isRead = true;
        selectedNotification.refresh();
      }

      final url = ApiConstants.markNotificationAsReadUrl;
      await ApiService.post(url, {
        'userId': userId,
        'notificationId': notification.id,
      });

    } catch (e) {
      // Revert optimistic update on failure
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        notifications[index].isRead = false;
        notifications.refresh();
      }
      TLoaders.warningSnackBar(title: "Error", message: "Unable to mark notification as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = currentUserId;
      if (userId.isEmpty) return;

      // Optimistic update
      for (var n in notifications) {
        n.isRead = true;
      }
      notifications.refresh();

      final url = ApiConstants.markAllNotificationsAsReadUrl;
      await ApiService.post(url, {
        'userId': userId,
      });

    } catch (e) {
      TLoaders.warningSnackBar(title: "Error", message: "Unable to mark all notifications as read: $e");
      // Could re-fetch to restore state, but keeping it simple for now
      fetchNotifications(refresh: true);
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}

