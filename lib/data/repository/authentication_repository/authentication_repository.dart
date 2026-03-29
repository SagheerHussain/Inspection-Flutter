import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inspection_app/data/services/notifications/notification_sevice.dart';

import '../../../features/authentication/controllers/login_controller.dart';
import '../../../features/authentication/screens/login/login_screen.dart';
import '../../../features/authentication/screens/signup/verify_email.dart';
import '../../../features/dashboard/course/screens/dashboard/coursesDashboard.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../utils/exceptions/firebase_auth_exceptions.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../../../utils/local_storage/storage_utility.dart';
import '../../../utils/popups/loaders.dart';
import '../../services/api/api_service.dart';
import '../user_repository/user_repository.dart';

/// -- README(Docs[6]) -- Bindings
class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage =
      GetStorage(); // Use this to store data locally (e.g. OnBoarding)
  late final Rx<User?> _firebaseUser;
  var phoneNo = ''.obs;
  var phoneNoVerificationId = ''.obs;
  var isPhoneAutoVerified = false;
  final _auth = FirebaseAuth.instance;
  int? _resendToken;

  /// Getters
  User? get firebaseUser => _firebaseUser.value;

  @Deprecated('Use userId instead')
  String get getUserID => userId;

  String get getUserEmail => firebaseUser?.email ?? "";
  String get getDisplayName => firebaseUser?.displayName ?? "";
  String get getPhoneNo => firebaseUser?.phoneNumber ?? "";

  /// Robust User ID getter for both Firebase and Custom Backend
  String get userId {
    // 1. Try Firebase
    if (firebaseUser != null && firebaseUser!.uid.isNotEmpty) {
      return firebaseUser!.uid;
    }

    // 2. Try Local Storage (Check multiple possible keys in default container)
    final keys = ['USER_ID', 'user_id', 'uid', 'mongodb_id', 'current_user_id'];
    for (var key in keys) {
      final val = deviceStorage.read(key)?.toString();
      if (val != null && val.isNotEmpty && val != 'null') {
        return val;
      }
    }

    // 3. Try TLocalStorage instance (Check if it's in a specific bucket)
    try {
      final val = TLocalStorage.instance().readData<String>('USER_ID');
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}

    return '';
  }

  /// Loads when app Launch from main.dart
  @override
  void onReady() {
    _firebaseUser = Rx<User?>(_auth.currentUser);
    _firebaseUser.bindStream(_auth.userChanges());
    screenRedirect(_firebaseUser.value);
    // ever(_firebaseUser, _setInitialScreen);
  }

  /// Function to Show Relevant Screen
  screenRedirect(User? user) async {
    final engineerNumber = deviceStorage.read('INSPECTION_ENGINEER_NUMBER');

    if (user != null) {
      // Fetch User Record
      await UserController.instance.fetchUserRecord();

      // Use this to check auth Role for admin
      final idTokenResult = await _auth.currentUser!.getIdTokenResult();

      // If email verified let the user go to Home Screen else to the Email Verification Screen
      if (user.emailVerified ||
          user.phoneNumber != null ||
          idTokenResult.claims?['admin'] == true) {
        // Initialize User Specific Storage
        await TLocalStorage.init(user.uid);
        Get.offAll(() => const CoursesDashboard());
      } else {
        Get.offAll(() => VerifyEmailScreen(email: getUserEmail));
      }
    } else if (engineerNumber != null && engineerNumber.toString().isNotEmpty) {
      // Persistent Login for Custom Backend (If Firebase user is null)
      final rawId = deviceStorage.read('USER_ID')?.toString();
      final userId = (rawId == null || rawId.isEmpty) ? 'engineer' : rawId;
      await TLocalStorage.init(userId);

      // ── NEW: Initialize UserController with stored data for CRM users ──
      await UserController.instance.fetchUserRecord();

      // Re-link device to user in OneSignal on app restart
      if (userId != 'engineer' && userId.toString().isNotEmpty) {
        await NotificationService.instance.login(userId);
      }

      Get.offAll(() => const CoursesDashboard());
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  /* ---------------------------- Email & Password sign-in ---------------------------------*/

  /// [EmailAuthentication] - SignIn
  Future<UserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [EmailAuthentication] - REGISTER
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [ReAuthenticate] - ReAuthenticate User
  Future<void> reAuthenticateWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Create a credential
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // ReAuthenticate
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [EmailAuthentication] - FORGET PASSWORD
  Future<void> sendPasswordResetEmail(email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /* ---------------------------- Federated identity & social sign-in ---------------------------------*/

  /// [GoogleAuthentication] - GOOGLE
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      // debugPrint('Something went wrong: $e');
      return null;
    }
  }

  /* ---------------------------- Phone Number sign-in ---------------------------------*/

  /// [PhoneAuthentication] - LOGIN - Register
  Future<void> loginWithPhoneNo(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _resendToken,
        timeout: const Duration(minutes: 2),
        verificationFailed: (e) async {
          // debugPrint('loginWithPhoneNo: verificationFailed => $e');
          await FirebaseCrashlytics.instance.recordError(e, e.stackTrace);

          if (e.code == 'too-many-requests') {
            // Get.offAllNamed(TRoutes.welcome);
            Get.offAll(() => const LoginScreen());
            TLoaders.warningSnackBar(
              title: 'Too many attempts',
              message:
                  'Oops! Too many tries. Take a short break and try again soon!',
            );
            return;
          } else if (e.code == 'unknown') {
            Get.back(result: false);
            TLoaders.warningSnackBar(
              title: 'SMS not Sent',
              message: 'An internal error has occurred, We are working on it!',
            );
            return;
          }
          TLoaders.warningSnackBar(title: 'Oh Snap', message: e.message ?? '');
        },
        codeSent: (verificationId, resendToken) {
          // debugPrint('--------------- codeSent');
          phoneNoVerificationId.value = verificationId;
          _resendToken = resendToken;
          // debugPrint('--------------- codeSent: $verificationId');
        },
        verificationCompleted: (credential) async {
          // debugPrint('--------------- verificationCompleted');
          var signedInUser = await _auth.signInWithCredential(credential);
          isPhoneAutoVerified = signedInUser.user != null;

          // await screenRedirect(
          //   _auth.currentUser,
          //   pinScreen: true,
          //   stopLoadingWhenReady: true,
          //   phoneNumber: phoneNumber,
          // );
          await screenRedirect(_auth.currentUser);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // phoneNoVerificationId.value = verificationId;
          // debugPrint(
          // '--------------- codeAutoRetrievalTimeout: $verificationId',
          // );
        },
      );
      phoneNo.value = phoneNumber;
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [PhoneAuthentication] - VERIFY PHONE NO BY OTP
  Future<bool> verifyOTP(String otp) async {
    try {
      final phoneCredentials = PhoneAuthProvider.credential(
        verificationId: phoneNoVerificationId.value,
        smsCode: otp,
      );
      var credentials = await _auth.signInWithCredential(phoneCredentials);
      return credentials.user != null ? true : false;
    } on FirebaseAuthException catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, e.stackTrace);
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    } finally {
      phoneNo.value = '';
      isPhoneAutoVerified = false;
    }
  }

  ///[FacebookAuthentication] - FACEBOOK
  // Future<UserCredential> signInWithFacebook() async {
  //   try {
  //     // Trigger the sign-in flow
  //     final LoginResult loginResult = await FacebookAuth.instance.login(permissions: ['email']);
  //
  //     // Create a credential from the access token
  //     final AccessToken accessToken = loginResult.accessToken!;
  //     final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(accessToken.tokenString);
  //
  //     // Once signed in, return the UserCredential
  //     return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  //   } on FirebaseAuthException catch (e) {
  //     throw TFirebaseAuthException(e.code).message;
  //   } on FirebaseException catch (e) {
  //     throw TFirebaseException(e.code).message;
  //   } on FormatException catch (_) {
  //     throw const TFormatException();
  //   } on PlatformException catch (e) {
  //     throw TPlatformException(e.code).message;
  //   } catch (e) {
  //     throw 'Something went wrong. Please try again';
  //   }
  // }

  /* ---------------------------- ./end Federated identity & social sign-in ---------------------------------*/

  /// [LogoutUser] - Valid for any authentication.
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();

      // Clear custom auth token and session data
      await ApiService.clearToken();
      await deviceStorage.remove('USER_ID');
      await deviceStorage.remove('USER_EMAIL');
      await deviceStorage.remove('USER_NAME');
      await deviceStorage.remove('USER_USERNAME');
      await deviceStorage.remove('USER_ROLE');
      await deviceStorage.remove('INSPECTION_ENGINEER_NUMBER');

      // Clear LoginController fields if registered to prevent auto-fill on next visit
      try {
        if (Get.isRegistered<LoginController>()) {
          final loginController = Get.find<LoginController>();
          loginController.userName.clear();
          loginController.password.clear();
        }
      } catch (_) {}

      Get.offAll(() => const LoginScreen());
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// DELETE USER - Remove user Auth and Firestore Account.
  Future<void> deleteAccount() async {
    try {
      await UserRepository.instance.removeUserRecord(_auth.currentUser!.uid);
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }
}
