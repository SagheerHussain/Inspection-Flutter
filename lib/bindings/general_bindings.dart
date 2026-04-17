import '../features/products/controllers/product_controller.dart';
import '../personalization/controllers/theme_controller.dart';
import 'package:get/get.dart';

import '../data/repository/authentication_repository/authentication_repository.dart';
import '../data/services/offline/offline_sync_service.dart';
import '../features/authentication/controllers/login_controller.dart';
import '../features/authentication/controllers/on_boarding_controller.dart';
import '../features/authentication/controllers/otp_controller.dart';
import '../features/authentication/controllers/signup_controller.dart';
import '../features/dashboard/course/controllers/dashboard_stats_controller.dart';
import '../data/services/offline/inspection_offload_service.dart';
import '../personalization/controllers/address_controller.dart';
import '../personalization/controllers/notification_controller.dart';
import '../personalization/controllers/environment_controller.dart';
import '../personalization/controllers/user_controller.dart';
import '../utils/helpers/network_manager.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.put(NetworkManager());

    /// -- Offline Sync Service (singleton, persists full app lifetime)
    Get.put(OfflineSyncService(), permanent: true);

    /// -- Inspection Offload Queue (persists inspections until fully synced)
    Get.put(InspectionOffloadService(), permanent: true);

    /// -- Dashboard Stats (permanent so it pre-fetches before the screen opens)
    Get.put(DashboardStatsController(), permanent: true);

    /// -- Repository
    Get.lazyPut(() => AuthenticationRepository(), fenix: true);
    Get.put(ThemeController());
    Get.put(ProductController());
    Get.lazyPut(() => UserController());
    Get.lazyPut(() => AddressController());
    Get.put(EnvironmentController());

    Get.lazyPut(() => OnBoardingController(), fenix: true);

    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut(() => SignUpController(), fenix: true);
    Get.lazyPut(() => OTPController(), fenix: true);
    Get.lazyPut(() => NotificationController(), fenix: true);
  }
}
