import 'package:inspection_app/data/services/notifications/notification_sevice.dart';

import '../../../utils/popups/exports.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/services/api/api_service.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../dashboard/course/screens/dashboard/coursesDashboard.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  /// TextField Controllers
  final hidePassword = true.obs;
  final localStorage = GetStorage();
  final userName = TextEditingController();
  final phoneNumber = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  /// Loader
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;

  @override
  void onInit() {
    // Pre-fill with saved credentials or default based on environment
    final isProd = ApiConstants.isProduction;

    userName.text =
        localStorage.read('REMEMBER_ME_USERNAME') ??
        (isProd ? 'Kazi Sohel Nawaz' : 'inspection');
    phoneNumber.text =
        localStorage.read('REMEMBER_ME_PHONE') ??
        (isProd ? '9830300302' : '9090909090');
    password.text =
        localStorage.read('REMEMBER_ME_PASSWORD') ??
        (isProd ? 'Kazi_S_N@1974#' : 'Admin@123');
    super.onInit();
  }

  /// Login using Otobix Backend API
  Future<void> login() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.docerAnimation,
      );

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        TLoaders.customToast(message: 'No Internet Connection');
        return;
      }

      // Form Validation
      if (!loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      final userPhone = phoneNumber.text.trim();

      // Call Backend API
      final response = await ApiService.post(ApiConstants.loginUrl, {
        'userName': userName.text.trim(),
        'phoneNumber': userPhone,
        'password': password.text.trim(),
      });

      // Role Check
      // Validating based on userType as per API response
      final userType = response['user']?['userType']?.toString() ?? '';
      if (userType != 'Inspection Engineer') {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: 'Access Denied',
          message: 'You are not authorized for this app',
        );
        return;
      }

      // Save auth token if present
      if (response['token'] != null) {
        await ApiService.saveToken(response['token']);
      }

      // Save credentials for remember me and session
      localStorage.write('REMEMBER_ME_USERNAME', userName.text.trim());
      localStorage.write('REMEMBER_ME_PHONE', userPhone);
      localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());

      // Specifically save the engineer number and details for future API calls
      localStorage.write('INSPECTION_ENGINEER_NUMBER', userPhone);
      
      // Robustly extract user ID from various possible keys
      final userObj = response['user'] as Map<String, dynamic>? ?? {};
      final storedUserId = (userObj['_id'] ?? userObj['id'] ?? userObj['uid'] ?? userObj['userId'])?.toString() ?? '';
      
      localStorage.write('USER_ID', storedUserId);
      localStorage.write('user_id', storedUserId);
      localStorage.write('uid', storedUserId);
      localStorage.write('mongodb_id', storedUserId);
      localStorage.write('USER_ROLE', userType);

      // Link device to user in OneSignal with MongoDB user ID
      final mongoUserId = response['user']?['_id']?.toString() ?? '';
      debugPrint(
        '🔑 LoginController: API user._id = "${response['user']?['_id']}"',
      );
      debugPrint('🔑 LoginController: mongoUserId = "$mongoUserId"');
      debugPrint(
        '🔑 LoginController: mongoUserId.isEmpty = ${mongoUserId.isEmpty}',
      );
      if (mongoUserId.isNotEmpty) {
        debugPrint(
          '🔑 LoginController: Calling NotificationService.login("$mongoUserId")...',
        );
        await NotificationService.instance.login(mongoUserId);
        debugPrint('🔑 LoginController: NotificationService.login() completed');
      } else {
        debugPrint(
          '⚠️ LoginController: mongoUserId is EMPTY — skipping OneSignal login!',
        );
      }

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success
      TLoaders.successSnackBar(title: 'Welcome!', message: 'Login successful');

      // Navigate to Dashboard
      Get.offAll(() => const CoursesDashboard());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
    }
  }
}
