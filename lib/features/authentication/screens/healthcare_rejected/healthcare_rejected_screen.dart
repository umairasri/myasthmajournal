import 'package:asthma_app/common/widgets/logout_confirmation_dialog.dart';
import 'package:asthma_app/data/repositories/authentication/authentication_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:asthma_app/features/authentication/controllers/waiting_approval_controller.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/image_strings.dart';
import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:asthma_app/utils/constants/text_strings.dart';
import 'package:asthma_app/utils/helpers/helper_functions.dart';
import 'package:asthma_app/utils/popups/loaders.dart';
import 'package:lottie/lottie.dart';

class HealthcareRejectedScreen extends StatelessWidget {
  const HealthcareRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WaitingApprovalController());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(CupertinoIcons.clear),
              onPressed: () async {
                await AuthenticationRepository.instance.logout();
              }),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                TImages.rejectedAnimation,
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.3,
              ), // Display Lottie animation

              const SizedBox(height: TSizes.spaceBtwSections),
              Text(
                'Account Rejected',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                'Your healthcare provider account is currently rejected from our administrators. This might be due to incomplete or incorrect information provided in the application.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections + 12),

              // // Buttons
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: controller.isLoading.value
              //         ? null
              //         : () => controller.checkApprovalStatus(),
              //     child: controller.isLoading.value
              //         ? const SizedBox(
              //             height: 20,
              //             width: 20,
              //             child: CircularProgressIndicator(strokeWidth: 2),
              //           )
              //         : const Text('Check Status'),
              //   ),
              // ),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],
          ),
        ),
      ),
    );
  }
}
