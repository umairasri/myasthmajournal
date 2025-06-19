import 'package:flutter/material.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:get/get.dart';
import 'package:asthma_app/features/asthma/controllers/medication_controller.dart';
import 'package:asthma_app/features/personalization/controllers/selected_dependent_controller.dart';
import 'package:intl/intl.dart';

class MedicationStatisticsCards extends StatefulWidget {
  const MedicationStatisticsCards({super.key});

  @override
  State<MedicationStatisticsCards> createState() =>
      _MedicationStatisticsCardsState();
}

class _MedicationStatisticsCardsState extends State<MedicationStatisticsCards> {
  final MedicationController _medicationController = Get.find();
  final SelectedDependentController _selectedDependentController = Get.find();
  String _selectedFilter = 'Today';

  int _getTotalMedications() {
    final now = DateTime.now();
    final String currentUserId =
        _selectedDependentController.getSelectionUserId();
    final medications = _medicationController.medications
        .where((m) => m.userId == currentUserId)
        .toList();

    DateTime startDate;
    switch (_selectedFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    return medications.where((medication) {
      final medicationDate = DateFormat('yyyy-MM-dd').parse(medication.date);
      return medicationDate.isAfter(startDate) ||
          (medicationDate.year == startDate.year &&
              medicationDate.month == startDate.month &&
              medicationDate.day == startDate.day);
    }).fold<int>(0, (sum, m) => sum + m.medication.length);
  }

  double _getMedicationAdherenceRate() {
    final now = DateTime.now();
    final String currentUserId =
        _selectedDependentController.getSelectionUserId();
    final medications = _medicationController.medications
        .where((m) => m.userId == currentUserId)
        .toList();

    DateTime startDate;
    int totalDays;
    switch (_selectedFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        totalDays = 1;
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        totalDays = 7;
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        totalDays = DateTime(now.year, now.month + 1, 0).day;
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        totalDays = 1;
    }

    final daysWithMedications = medications
        .where((medication) {
          final medicationDate =
              DateFormat('yyyy-MM-dd').parse(medication.date);
          return medicationDate.isAfter(startDate) ||
              (medicationDate.year == startDate.year &&
                  medicationDate.month == startDate.month &&
                  medicationDate.day == startDate.day);
        })
        .map((m) => m.date)
        .toSet()
        .length;

    return (daysWithMedications / totalDays) * 100;
  }

  String _getAdherenceLevel() {
    final adherenceRate = _getMedicationAdherenceRate();
    if (adherenceRate <= 25) return "Excellent";
    if (adherenceRate <= 50) return "Good";
    if (adherenceRate <= 75) return "Fair";
    return "Poor";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
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
                items: ['Today', 'This Week', 'This Month'].map((String value) {
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
        const SizedBox(height: TSizes.spaceBtwSections),

        // Statistics Cards
        Row(
          children: [
            // Total Medications Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(TSizes.sm + 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total\nMedications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: TColors.darkGrey,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(width: TSizes.xs * 2),
                    Text(
                      _getTotalMedications().toString(),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: TColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 45,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems - 3),
            // Adherence Level Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adherence Level',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: TColors.darkGrey,
                          ),
                    ),
                    const SizedBox(height: TSizes.sm),
                    Text(
                      _getAdherenceLevel(),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: TColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: TSizes.xs),
                    Text(
                      '${_getMedicationAdherenceRate().toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TColors.darkGrey,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
