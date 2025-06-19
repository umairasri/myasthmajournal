import 'package:asthma_app/common/widgets/custom_shapes/containers/search_container_func.dart';
import 'package:asthma_app/features/asthma/controllers/symptom_controller.dart';
import 'package:asthma_app/features/asthma/models/symptom_model.dart';
import 'package:asthma_app/features/asthma/screens/home/homePage.dart';
import 'package:asthma_app/features/personalization/controllers/patient_controller.dart';
import 'package:asthma_app/features/personalization/controllers/selected_dependent_controller.dart';
import 'package:asthma_app/navigation_menu.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/image_strings.dart';
import 'package:asthma_app/utils/helpers/helper_functions.dart';
import 'package:asthma_app/utils/popups/loaders.dart';
import 'package:asthma_app/utils/popups/full_screen_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/sizes.dart';

class TSymptomTab extends StatefulWidget {
  const TSymptomTab({super.key});

  @override
  State<TSymptomTab> createState() => _TSymptomTabState();
}

class _TSymptomTabState extends State<TSymptomTab> {
  final List<String> _symptoms = [
    'Cough',
    'Chest Compression',
    'Wheezing',
    'Stress',
    'Fever',
    'Dizziness',
    'Fast Heartbeat',
    'Shortness of breath',
    'Rapid Breathing',
    'Headache',
  ];

  final Map<String, String> _symptomIcons = {
    'Cough': TImages.coughIcon,
    'Chest Compression': TImages.chestIcon,
    'Wheezing': TImages.coughIcon,
    'Stress': TImages.dizzinessIcon,
    'Fever': TImages.temperatureIcon,
    'Dizziness': TImages.dizzinessIcon,
    'Fast Heartbeat': TImages.heartbeatIcon,
    'Shortness of breath': TImages.lungsIcon,
    'Rapid Breathing': TImages.lungsIcon,
    'Headache': TImages.dizzinessIcon,
  };

  final Set<String> _selectedSymptoms = {};
  TimeOfDay _selectedTime = TimeOfDay.now(); // Time of day for symptom logging

  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredSymptoms =
      []; // List of symptoms filtered based on search

  @override
  void initState() {
    super.initState();
    _filteredSymptoms = _symptoms; // Initialize with all symptoms
    _searchController
        .addListener(_filterMedications); // Add listener for search input
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      _selectedSymptoms.contains(symptom)
          ? _selectedSymptoms.remove(symptom)
          : _selectedSymptoms.add(symptom);
    });
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null && time != _selectedTime) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  // Function to filter symptoms based on the search query
  void _filterMedications() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSymptoms = _symptoms
          .where((symptom) => symptom.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _submitSymptoms() async {
    try {
      if (_selectedSymptoms.isEmpty) {
        TLoaders.warningSnackBar(
            title: 'Warning', message: 'Please select at least one symptom');
        return;
      }

      final selectedDependentController =
          Get.find<SelectedDependentController>();
      final userId = selectedDependentController.getSelectionUserId();

      if (userId.isEmpty) {
        TLoaders.errorSnackBar(
            title: 'Error', message: 'Please select a patient or dependent');
        return;
      }

      // Show loading indicator
      TFullScreenLoader.openLoadingDialog(
          'Saving symptoms...', TImages.docerAnimation);

      final now = DateTime.now();

      // Build list of symptoms with name and icon
      final List<Map<String, String>> symptomData =
          _selectedSymptoms.map((symptom) {
        return {
          'name': symptom,
          'icon': _symptomIcons[symptom] ?? TImages.coughIcon,
        };
      }).toList();

      // Create SymptomModel object with date and timeInMinutes
      final symptomModel = SymptomModel(
        id: '',
        symptom: symptomData,
        userId: userId,
        date: SymptomModel.formatDate(now),
        time: SymptomModel.formatTime(_selectedTime),
      );

      // Save the symptom
      await SymptomController.instance.addSymptom(symptomModel);

      // Close loading indicator
      TFullScreenLoader.stopLoading();

      // Show success message
      TLoaders.successSnackBar(
          title: 'Success', message: 'Symptoms recorded successfully');

      // Reset state after a short delay
      Future.microtask(() {
        setState(() {
          _selectedSymptoms.clear();
          _selectedTime = TimeOfDay.now();
        });
      });

      // Navigate to home page with bottom navigation
      Get.offAll(() => const NavigationMenu());
    } catch (e) {
      // Close loading indicator if it's open
      TFullScreenLoader.stopLoading();

      // Show error message
      TLoaders.errorSnackBar(
          title: 'Error', message: 'Failed to save symptoms: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); // Clean up the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Record Your Symptoms',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'Select the symptoms you\'re experiencing',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? TColors.darkerGrey : TColors.light,
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TSearchContainerFunc(
                    text: 'Search symptoms...',
                    controller: _searchController,
                    showBorder: false,
                    showBackground: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.defaultSpace),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Symptom List
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? TColors.darkerGrey : TColors.light,
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredSymptoms.length,
                    separatorBuilder: (context, index) => Divider(
                      color: isDark ? TColors.darkGrey : TColors.grey,
                      thickness: 0.5,
                      indent: 60,
                      endIndent: 5,
                    ),
                    itemBuilder: (context, index) {
                      final symptom = _filteredSymptoms[index];
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? TColors.primary.withOpacity(0.1)
                                  : TColors.primary.withOpacity(0.05))
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(TSizes.cardRadiusMd),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? TColors.darkGrey : TColors.light,
                              borderRadius:
                                  BorderRadius.circular(TSizes.cardRadiusSm),
                            ),
                            child: Image.asset(
                              _symptomIcons[symptom] ?? TImages.coughIcon,
                              height: 24,
                              width: 24,
                            ),
                          ),
                          title: Text(
                            symptom,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color:
                                  isSelected ? TColors.primary : TColors.grey,
                              key: ValueKey<bool>(isSelected),
                            ),
                          ),
                          onTap: () => _toggleSymptom(symptom),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Time Selection
                Container(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  decoration: BoxDecoration(
                    color: isDark ? TColors.darkerGrey : TColors.light,
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: TColors.primary),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      TextButton(
                        onPressed: () => _selectTime(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: TSizes.defaultSpace),
                        ),
                        child: Text(
                          'Time: ${_selectedTime.format(context)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? TColors.white : TColors.dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitSymptoms,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: TSizes.buttonHeight),
                      backgroundColor: TColors.primary,
                      foregroundColor: TColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(TSizes.buttonRadius),
                      ),
                    ),
                    child: const Text(
                      'Record Symptoms',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
