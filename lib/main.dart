import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:inspection_app/data/services/notifications/notification_sevice.dart';

import 'app.dart';
import 'data/repository/authentication_repository/authentication_repository.dart';
import 'firebase_options.dart';

/// ------ For Docs & Updates Check ------
/// ------------- README.md --------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// -- Native Scroll & Edge-to-Edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  /// -- README(Update[]) -- GetX Local Storage
  await GetStorage.init();

  /// -- README(Docs[2]) -- Initialize Firebase & Authentication Repository
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) => Get.put(AuthenticationRepository()));

  /// -- Initialize OneSignal Notifications
  await NotificationService.instance.init();

  /// -- Main App Starts here (app.dart) ...
  runApp(const App());
}
