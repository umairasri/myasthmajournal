import 'package:asthma_app/common/widgets/asthma_diary/unified_medication_analysis.dart';
import 'package:flutter/material.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/sizes.dart';

class MedicationAnalysis extends StatelessWidget {
  const MedicationAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        child: Column(
          children: [
            const SizedBox(height: TSizes.spaceBtwSections),
            const UnifiedMedicationAnalysis(showFilter: true),
            const SizedBox(height: TSizes.spaceBtwSections + 150),
          ],
        ),
      ),
    );
  }
}
