import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asthma_app/features/asthma/controllers/medication_controller.dart';
import 'package:asthma_app/features/personalization/controllers/patient_controller.dart';
import 'package:asthma_app/features/personalization/controllers/selected_dependent_controller.dart';
import 'package:asthma_app/features/asthma/controllers/selected_date_controller.dart';
import 'package:asthma_app/utils/constants/image_strings.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/features/asthma/models/medication_model.dart';
import 'package:asthma_app/utils/logger.dart';
import 'package:asthma_app/features/notification/noti_service.dart';
import 'package:asthma_app/navigation_menu.dart';
import 'package:asthma_app/features/asthma/screens/diary/diary.dart';

class TodayMedicationUsage extends StatefulWidget {
  final bool showFilter;

  const TodayMedicationUsage({
    super.key,
    this.showFilter = false,
  });

  @override
  State<TodayMedicationUsage> createState() => _TodayMedicationUsageState();
}

class _TodayMedicationUsageState extends State<TodayMedicationUsage> {
  String _selectedFilter = 'Today';
  final Map<String, String> medicationIcons = {
    'Blue Inhaler Salbutamol': TImages.inhaler,
    'Gas Nebulizer': TImages.nebulizer,
    'Ventolin Syrup': TImages.syrup,
  };

  final List<String> medications = [
    'Blue Inhaler Salbutamol',
    'Gas Nebulizer',
    'Ventolin Syrup',
  ];

  final MedicationController _medicationController =
      Get.find<MedicationController>();
  final PatientController _userController = Get.find<PatientController>();
  final SelectedDependentController _selectedDependentController =
      Get.find<SelectedDependentController>();
  final SelectedDateController _selectedDateController =
      Get.find<SelectedDateController>();
  final _storage = GetStorage();

  void _navigateToDiaryWithMedicationTab() {
    // Get the navigation controller
    final navigationController = Get.find<NavigationController>();

    // Create a new DiaryScreen with medication tab selected
    final diaryScreen = const DiaryScreen(initialTabIndex: 1);

    // Update the screens array with the new DiaryScreen
    navigationController.screens[1] = diaryScreen;

    // Set the selected index to diary screen (index 1)
    navigationController.selectedIndex.value = 1;
  }

  String _getStorageKey(String userId, DateTime date) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return 'lastNotifiedUsage_${userId}_${formattedDate}_BlueInhaler';
  }

  Map<String, int> _calculateUsage() {
    try {
      final selectedDate = _selectedDateController.selectedDate;
      final String currentUserId =
          _selectedDependentController.getSelectionUserId();
      DateTime startDate;
      DateTime endDate;

      // Set the time range based on the selected filter
      switch (_selectedFilter) {
        case 'Today':
          startDate =
              DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          endDate = DateTime(selectedDate.year, selectedDate.month,
              selectedDate.day, 23, 59, 59);
          break;
        case 'This Week':
          startDate =
              selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = startDate.add(
              const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          break;
        case 'This Month':
          startDate = DateTime(selectedDate.year, selectedDate.month, 1);
          endDate = DateTime(
              selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
          break;
        default:
          startDate =
              DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          endDate = DateTime(selectedDate.year, selectedDate.month,
              selectedDate.day, 23, 59, 59);
      }

      TLogger.debug('Calculating usage for period: $_selectedFilter');
      TLogger.debug('Start date: ${MedicationModel.formatDate(startDate)}');
      TLogger.debug('End date: ${MedicationModel.formatDate(endDate)}');

      // Filter medications for the selected period
      final List<MedicationModel> filteredMedications =
          _medicationController.medications.where((m) {
        final medicationDate = DateFormat('yyyy-MM-dd').parse(m.date);
        return m.userId == currentUserId &&
            medicationDate
                .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            medicationDate.isBefore(endDate.add(const Duration(seconds: 1)));
      }).toList();

      TLogger.debug(
          'Filtered medications count: ${filteredMedications.length}');

      // Initialize usage count for all medications
      final Map<String, int> usageCount = {
        for (var med in medications) med: 0,
      };

      // Count medication usage
      for (final med in filteredMedications) {
        if (med.medication.isEmpty) {
          TLogger.warning(
              'Empty medication list found for medication with ID: ${med.id}');
          continue;
        }

        for (final m in med.medication) {
          final name = m['name'];
          if (name != null && usageCount.containsKey(name)) {
            usageCount[name] = usageCount[name]! + 1;
          }
        }
      }

      // Handle notifications only for today's data
      if (_selectedFilter == 'Today' && _selectedDateController.isToday()) {
        final currentBlueInhalerUsage =
            usageCount['Blue Inhaler Salbutamol'] ?? 0;
        final selectedDependent =
            _selectedDependentController.selectedDependent.value;
        final username =
            selectedDependent?.name ?? _userController.user.value.username;

        final DateTime todayForStorageKey =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final String storageKey =
            _getStorageKey(currentUserId, todayForStorageKey);
        final int lastNotifiedUsage = _storage.read<int>(storageKey) ?? 0;

        TLogger.debug(
            'Blue Inhaler Notif Check - User: $currentUserId, Date: ${DateFormat('yyyy-MM-dd').format(todayForStorageKey)}, Current Usage: $currentBlueInhalerUsage, Last Notified: $lastNotifiedUsage');

        if (currentBlueInhalerUsage > 4 &&
            currentBlueInhalerUsage > lastNotifiedUsage) {
          NotiService().showMedicationUsageWarning(username: username);
          _storage.write(storageKey, currentBlueInhalerUsage);
          TLogger.info(
              'Medication usage warning SENT for $username. Current: $currentBlueInhalerUsage. Stored new last notified: $currentBlueInhalerUsage for key: $storageKey');
        } else {
          TLogger.debug(
              'Medication usage warning NOT SENT for $username. Condition (current > 4 && current > lastNotified) not met. Current: $currentBlueInhalerUsage, Last Notified: $lastNotifiedUsage');
        }
      }

      TLogger.debug('Final usage count for UI: $usageCount');
      return usageCount;
    } catch (e, stackTrace) {
      TLogger.error('Error calculating usage', e, stackTrace);
      return {for (var med in medications) med: 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Ensure medications are loaded
      if (_medicationController.medications.isEmpty) {
        _medicationController.fetchMedications();
      }

      final usage = _calculateUsage();
      return GestureDetector(
        onTap: _navigateToDiaryWithMedicationTab,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showFilter) ...[
              /// -- Title with Filter
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Medication Usage',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .apply(color: TColors.darkGrey)
                          .copyWith(fontSize: 16),
                    ),
                    Container(
                      width: 120,
                      padding:
                          const EdgeInsets.symmetric(horizontal: TSizes.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(TSizes.cardRadiusLg),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        underline: const SizedBox(),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: ['Today', 'This Week', 'This Month']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFilter = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            /// -- Body Container
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              decoration: BoxDecoration(
                color: TColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: medications.map((med) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Image.asset(
                          medicationIcons[med] ?? TImages.inhaler,
                          height: 36,
                          width: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            usage[med].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }
}
