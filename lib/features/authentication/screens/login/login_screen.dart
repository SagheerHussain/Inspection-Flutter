import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../common/widgets/form/form_header_widget.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';

import 'widgets/login_form_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _version = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = "${packageInfo.version}+${packageInfo.buildNumber}";
        });
      }
    } catch (e) {
      debugPrint("Error loading version: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Decorative background element
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: TSizes.appBarHeight + 20),
                      const FormHeaderWidget(
                        image: TImages.tLogoImage,
                        title: "Engineer Login",
                        subTitle:
                            "Welcome back, please enter your details to continue.",
                        imageHeight: 0.16,
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),
                      const LoginFormWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Always provide a bottomNavigationBar to avoid layout jumps/animations
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _version.isNotEmpty ? "Version $_version" : "Loading version...",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade400,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
