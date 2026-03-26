import 'package:inspection_app/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../../../common/widgets/buttons/primary_button.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../controllers/login_controller.dart';

class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xl),
      child: Form(
        key: controller.loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -- Username Field
            TextFormField(
              validator:
                  (value) => TValidator.validateEmptyText('Username', value),
              controller: controller.userName,
              decoration: const InputDecoration(
                prefixIcon: Icon(LineAwesomeIcons.user),
                labelText: 'Username',
                hintText: 'Enter your username',
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),

            /// -- Password Field
            Obx(
              () => TextFormField(
                obscureText: controller.hidePassword.value,
                controller: controller.password,
                validator:
                    (value) => TValidator.validateEmptyText('Password', value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.fingerprint),
                  labelText: TTexts.tPassword,
                  hintText: TTexts.tPassword,
                  suffixIcon: IconButton(
                    onPressed:
                        () =>
                            controller.hidePassword.value =
                                !controller.hidePassword.value,
                    icon: Icon(
                      controller.hidePassword.value
                          ? Iconsax.eye_slash
                          : Iconsax.eye,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),

            const SizedBox(height: TSizes.spaceBtwInputFields),

            /// -- LOGIN BTN
            Obx(
              () => TPrimaryButton(
                isLoading: controller.isLoading.value,
                text: TTexts.tLogin.tr,
                onPressed:
                    controller.isLoading.value
                        ? () {}
                        : () => controller.login(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
