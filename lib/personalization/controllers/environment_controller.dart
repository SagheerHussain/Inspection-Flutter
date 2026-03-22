import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/api_constants.dart';
import '../../features/authentication/controllers/login_controller.dart';

class EnvironmentController extends GetxController {
  static EnvironmentController get instance => Get.find();

  final RxString currentEnv = ApiConstants.environment.obs;

  bool get isProduction => currentEnv.value == 'production';

  Future<void> toggleEnvironment() async {
    await ApiConstants.toggleEnvironment();
    currentEnv.value = ApiConstants.environment;

    // Update Login Credentials automatically
    try {
      if (Get.isRegistered<LoginController>()) {
        final loginController = Get.find<LoginController>();
        if (isProduction) {
          loginController.userName.text = 'sagheer';
          loginController.phoneNumber.text = '9090909090';
          loginController.password.text = 'Admin@123';
        } else {
          loginController.userName.text = 'inspection';
          loginController.phoneNumber.text = '9090909090';
          loginController.password.text = 'Admin@123';
        }
      }
    } catch (e) {
      debugPrint('LoginController not yet initialized: $e');
    }

    Get.snackbar(
      'Environment Switched',
      'Now using ${currentEnv.value.capitalizeFirst} mode',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor:
          isProduction
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
      colorText: isProduction ? Colors.green : Colors.blue,
    );
  }
}
