import 'package:asthma_app/common/widgets/custom_shapes/containers/search_container_func.dart';
import 'package:asthma_app/features/asthma/controllers/medication_controller.dart';
import 'package:asthma_app/features/asthma/models/medication_model.dart';
import 'package:asthma_app/features/personalization/controllers/patient_controller.dart';
import 'package:asthma_app/features/personalization/controllers/selected_dependent_controller.dart';
import 'package:asthma_app/navigation_menu.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/image_strings.dart';
import 'package:asthma_app/utils/helpers/helper_functions.dart';
import 'package:asthma_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/sizes.dart';

class TMedicationTab extends StatefulWidget {
  const TMedicationTab({super.key});

  @override
  State<TMedicationTab> createState() => _TMedicationTabState();
}

class _TMedicationTabState extends State<TMedicationTab> {
  final List<String> _medications = [
    'Blue Inhaler Salbutamol',
    'Gas Nebulizer',
    'Ventolin Syrup',
  ];

  final Map<String, String> _medicationIcons = {
    'Blue Inhaler Salbutamol': TImages.inhaler,
    'Gas Nebulizer': TImages.nebulizer,
    'Ventolin Syrup': TImages.syrup,
  };

  final Set<String> _selectedMedications = {};
  TimeOfDay _selectedTime =
      TimeOfDay.now(); // Time of day for medications logging

  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredMedications =
      []; // List of medications filtered based on search

  @override
  void initState() {
    super.initState();
    _filteredMedications = _medications; // Initialize with all medications
    _searchController
        .addListener(_filterMedications); // Add listener for search input
  }

  void _toggleMedication(String medication) {
    setState(() {
      _selectedMedications.contains(medication)
          ? _selectedMedications.remove(medication)
          : _selectedMedications.add(medication);
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

  // Function to filter medications based on the search query
  void _filterMedications() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedications = _medications
          .where((medication) => medication.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _submitMedications() async {
    try {
      if (_selectedMedications.isEmpty) return;

      final selectedDependentController =
          Get.find<SelectedDependentController>();
      final userId = selectedDependentController.getSelectionUserId();

      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      final now = DateTime.now();

      // Build list of medications with name and icon
      final List<Map<String, String>> medicationData =
          _selectedMedications.map((medication) {
        return {
          'name': medication,
          'icon': _medicationIcons[medication] ?? TImages.inhaler,
        };
      }).toList();

      // Create MedicationModel object with date and timeInMinutes
      final medicationModel = MedicationModel(
        id: '',
        medication: medicationData,
        userId: userId,
        date: MedicationModel.formatDate(now),
        time: MedicationModel.formatTime(_selectedTime),
      );

      // Save the medication
      await MedicationController.instance.addMedication(medicationModel);

      TLoaders.successSnackBar(
          title: 'Saved!', message: 'Medications recorded.');

      setState(() {
        _selectedMedications.clear();
        _selectedTime = TimeOfDay.now();
      });

      // Navigate to home page with bottom navigation
      Get.offAll(() => const NavigationMenu());
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save: $e');
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
                  'Record Your Medications',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'Select the medications you\'ve taken',
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
                    text: 'Search medications...',
                    controller: _searchController,
                    showBorder: false,
                    showBackground: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.defaultSpace),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Medication List
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? TColors.darkerGrey : TColors.light,
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredMedications.length,
                    separatorBuilder: (context, index) => Divider(
                      color: isDark ? TColors.darkGrey : TColors.grey,
                      thickness: 0.5,
                      indent: 60,
                      endIndent: 5,
                    ),
                    itemBuilder: (context, index) {
                      final medication = _filteredMedications[index];
                      final isSelected =
                          _selectedMedications.contains(medication);
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
                              _medicationIcons[medication] ?? TImages.inhaler,
                              height: 24,
                              width: 24,
                            ),
                          ),
                          title: Text(
                            medication,
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
                          onTap: () => _toggleMedication(medication),
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
                    onPressed: _submitMedications,
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
                      'Record Medications',
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
