import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:inspection_app/data/services/notifications/notification_sevice.dart';

import '../../../utils/popups/exports.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../../../../utils/constants/enums.dart';
import '../../../../../../utils/constants/api_constants.dart';
import '../../../../../../data/services/api/api_service.dart';
import '../../../../../../personalization/controllers/user_controller.dart';
import '../../../../../../personalization/models/user_model.dart';
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
    super.onInit();
    _loadSecureCredentials();
  }

  Future<void> _loadSecureCredentials() async {
    try {
      const secureStorage = FlutterSecureStorage();
      final savedUser = await secureStorage.read(key: 'SECURE_USERNAME');
      final savedPass = await secureStorage.read(key: 'SECURE_PASSWORD');
      
      if (savedUser != null && savedPass != null && savedUser.isNotEmpty && savedPass.isNotEmpty) {
        userName.text = savedUser;
        password.text = savedPass;
        TLoaders.customToast(message: 'Loaded securely from Keychain!');
        await _tryBiometricLogin();
      } else {
        // Fallback to local storage if empty completely
        userName.text = localStorage.read('SAVED_USERNAME') ?? '';
        password.text = localStorage.read('SAVED_PASSWORD') ?? '';
        if (userName.text.isNotEmpty) {
          TLoaders.customToast(message: 'Loaded from Local fallback!');
          await _tryBiometricLogin();
        }
      }
    } catch (e) {
      debugPrint("Error reading secure storage: $e");
      TLoaders.errorSnackBar(title: 'Keychain Read Error', message: e.toString());
      
      // Fallback to local storage if keychain fails (like in simulators)
      userName.text = localStorage.read('SAVED_USERNAME') ?? '';
      password.text = localStorage.read('SAVED_PASSWORD') ?? '';

      if (userName.text.isNotEmpty && password.text.isNotEmpty) {
        await _tryBiometricLogin();
      }
    }
  }

  Future<void> _tryBiometricLogin() async {
    try {
      final localAuth = LocalAuthentication();
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics && !isDeviceSupported) return;

      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to safely log in',
      );

      if (didAuthenticate) {
        await login();
      }
    } catch (e) {
      // Ignore auth cancellations or errors silently without blocking login screen
    }
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

      // 1. Authenticate using Custom CRM API
      Map<String, dynamic> response;
      if (userName.text.trim() == 'superadmin' &&
          password.text.trim() == 'Abc123***') {
        // Superadmin Bypass
        response = {
          'user': {
            '_id': 'superadmin',
            'fullName': 'Super Admin',
            'userName': 'superadmin',
            'email': 'superadmin@otobix.in',
            'phoneNumber': '000000000',
            'role': 'admin',
            'verificationStatus': 'approved',
            'isEmailVerified': true,
            'isProfileActive': true,
          },
          'token': 'superadmin_token',
        };
      } else {
        response = await ApiService.post(ApiConstants.loginUrl, {
          'userName': userName.text.trim(),
          'password': password.text.trim(),
        });
      }

      // Check if response contains user data
      if (response['user'] == null) {
        throw 'Invalid response from server. No user found.';
      }

      // 2. Map response to UserModel and perform local checks
      final userData = response['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData['_id'] ?? '', userData);

      // 3. Only allow login for users whose status is "Approved"
      if (user.verificationStatus != VerificationStatus.approved) {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: 'Account Not Approved',
          message:
              'Your account is currently ${user.verificationStatus.name}. Please contact support.',
        );
        return;
      }

      // 4. Persistence - Save user IDs and roles for the rest of the app
      final userController = Get.put(UserController());
      userController.user.value = user;

      final String storedUserId = user.id;
      localStorage.write('USER_ID', storedUserId);
      localStorage.write('user_id', storedUserId);
      localStorage.write('uid', storedUserId);
      localStorage.write('mongodb_id', storedUserId);
      localStorage.write('SAVED_USERNAME', userName.text.trim());
      localStorage.write('SAVED_PASSWORD', password.text.trim());
      localStorage.write('USER_EMAIL', user.email);
      localStorage.write('USER_NAME', user.fullName);
      localStorage.write('USER_USERNAME', user.userName);
      localStorage.write('INSPECTION_ENGINEER_NUMBER', user.phoneNumber);
      localStorage.write('USER_ROLE', user.role.name);

      try {
        // Save securely to OS keychain for biometrics
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(key: 'SECURE_USERNAME', value: userName.text.trim());
        await secureStorage.write(key: 'SECURE_PASSWORD', value: password.text.trim());
        TLoaders.customToast(message: 'Credentials pushed to Keychain');
      } catch (e) {
        debugPrint("Error writing securely: $e");
        TLoaders.errorSnackBar(title: 'Keychain Write Error', message: e.toString());
      }

      // Save token if present
      if (response['token'] != null) {
        await ApiService.saveToken(response['token']);
      }

      // Link device to user in OneSignal
      if (storedUserId.isNotEmpty) {
        await NotificationService.instance.login(storedUserId);
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
