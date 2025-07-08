import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asthma_app/features/asthma/controllers/medication_controller.dart';
import 'package:asthma_app/features/personalization/controllers/patient_controller.dart';
import 'package:asthma_app/features/personalization/controllers/selected_dependent_controller.dart';
import 'package:asthma_app/features/asthma/controllers/selected_date_controller.dart';
import 'package:asthma_app/utils/constants/image_strings.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:asthma_app/features/asthma/models/medication_model.dart';
import 'package:asthma_app/utils/logger.dart';
import 'package:asthma_app/features/notification/noti_service.dart';
import 'package:asthma_app/navigation_menu.dart';
import 'package:asthma_app/features/asthma/screens/diary/diary.dart';

enum TrendType { daily, weekly, monthly }

class UnifiedMedicationAnalysis extends StatefulWidget {
  final bool showFilter;

  const UnifiedMedicationAnalysis({
    super.key,
    this.showFilter = false,
  });

  @override
  State<UnifiedMedicationAnalysis> createState() =>
      _UnifiedMedicationAnalysisState();
}

class _UnifiedMedicationAnalysisState extends State<UnifiedMedicationAnalysis> {
  String _selectedFilter = 'Today';
  TrendType selectedTrend = TrendType.daily;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

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
    final navigationController = Get.find<NavigationController>();
    final diaryScreen = const DiaryScreen(initialTabIndex: 1);
    navigationController.screens[1] = diaryScreen;
    navigationController.selectedIndex.value = 1;
  }

  String _getStorageKey(String userId, DateTime date) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return 'lastNotifiedUsage_${userId}_${formattedDate}_BlueInhaler';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    // Show start date picker
    final DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: TColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (startDate != null) {
      // Show end date picker
      final DateTime? endDate = await showDatePicker(
        context: context,
        initialDate: _selectedEndDate ?? startDate,
        firstDate: startDate,
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: TColors.primary,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (endDate != null) {
        setState(() {
          _selectedStartDate = startDate;
          _selectedEndDate = endDate;
          _selectedFilter = 'Custom Date';
        });
      }
    }
  }

  // Statistics Cards Methods
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
      case 'Custom Date':
        if (_selectedStartDate != null) {
          startDate = DateTime(_selectedStartDate!.year,
              _selectedStartDate!.month, _selectedStartDate!.day);
        } else {
          startDate = DateTime(now.year, now.month, now.day);
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    return medications.where((medication) {
      final medicationDate = DateFormat('yyyy-MM-dd').parse(medication.date);
      if (_selectedFilter == 'Custom Date' &&
          _selectedStartDate != null &&
          _selectedEndDate != null) {
        return medicationDate.isAfter(
                _selectedStartDate!.subtract(const Duration(days: 1))) &&
            medicationDate
                .isBefore(_selectedEndDate!.add(const Duration(days: 1)));
      }
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
      case 'Custom Date':
        if (_selectedStartDate != null && _selectedEndDate != null) {
          startDate = DateTime(_selectedStartDate!.year,
              _selectedStartDate!.month, _selectedStartDate!.day);
          totalDays =
              _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;
        } else {
          startDate = DateTime(now.year, now.month, now.day);
          totalDays = 1;
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        totalDays = 1;
    }

    final daysWithMedications = medications
        .where((medication) {
          final medicationDate =
              DateFormat('yyyy-MM-dd').parse(medication.date);
          if (_selectedFilter == 'Custom Date' &&
              _selectedStartDate != null &&
              _selectedEndDate != null) {
            return medicationDate.isAfter(
                    _selectedStartDate!.subtract(const Duration(days: 1))) &&
                medicationDate
                    .isBefore(_selectedEndDate!.add(const Duration(days: 1)));
          }
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

  // Medication Usage Analysis Methods
  Map<String, int> _calculateUsage() {
    try {
      final selectedDate = _selectedDateController.selectedDate;
      final String currentUserId =
          _selectedDependentController.getSelectionUserId();
      DateTime startDate;
      DateTime endDate;

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
        case 'Custom Date':
          if (_selectedStartDate != null && _selectedEndDate != null) {
            startDate = DateTime(_selectedStartDate!.year,
                _selectedStartDate!.month, _selectedStartDate!.day);
            endDate = DateTime(_selectedEndDate!.year, _selectedEndDate!.month,
                _selectedEndDate!.day, 23, 59, 59);
          } else {
            startDate = DateTime(
                selectedDate.year, selectedDate.month, selectedDate.day);
            endDate = DateTime(selectedDate.year, selectedDate.month,
                selectedDate.day, 23, 59, 59);
          }
          break;
        default:
          startDate =
              DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          endDate = DateTime(selectedDate.year, selectedDate.month,
              selectedDate.day, 23, 59, 59);
      }

      final List<MedicationModel> filteredMedications =
          _medicationController.medications.where((m) {
        final medicationDate = DateFormat('yyyy-MM-dd').parse(m.date);
        return m.userId == currentUserId &&
            medicationDate
                .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            medicationDate.isBefore(endDate.add(const Duration(seconds: 1)));
      }).toList();

      final Map<String, int> usageCount = {for (var med in medications) med: 0};

      for (final med in filteredMedications) {
        if (med.medication.isEmpty) continue;
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

        if (currentBlueInhalerUsage > 4 &&
            currentBlueInhalerUsage > lastNotifiedUsage) {
          NotiService().showMedicationUsageWarning(username: username);
          _storage.write(storageKey, currentBlueInhalerUsage);
        }
      }

      return usageCount;
    } catch (e, stackTrace) {
      TLogger.error('Error calculating usage', e, stackTrace);
      return {for (var med in medications) med: 0};
    }
  }

  // Chart Methods
  Color _getColorForMedication(String name) {
    final lowerCaseName = name.toLowerCase();
    if (lowerCaseName.contains('inhaler')) return Colors.blue;
    if (lowerCaseName.contains('nebulizer')) return Colors.green;
    if (lowerCaseName.contains('syrup')) return Colors.orange;
    return Colors.grey;
  }

  Set<String> _getMedicationTypes() {
    final currentUserId = _selectedDependentController.getSelectionUserId();
    final types = <String>{};
    for (final m in _medicationController.medications) {
      if (m.userId == currentUserId) {
        for (final med in m.medication) {
          if (med.containsKey('name')) {
            types.add(med['name']!);
          }
        }
      }
    }
    return types;
  }

  Map<String, List<int>> _getMedicationCountsByType() {
    final now = DateTime.now();
    final currentUserId = _selectedDependentController.getSelectionUserId();
    final types = _getMedicationTypes();
    final Map<String, List<int>> countsByType = {
      for (var t in types) t: List.filled(7, 0)
    };

    for (final type in types) {
      for (int i = 0; i < 7; i++) {
        bool Function(MedicationModel m) dateMatch;
        switch (selectedTrend) {
          case TrendType.daily:
            final day = now.subtract(Duration(days: 6 - i));
            final dateString = DateFormat('yyyy-MM-dd').format(day);
            dateMatch = (m) => m.date == dateString;
            break;
          case TrendType.weekly:
            final startOfWeek = now.subtract(Duration(days: (6 - i) * 7));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            final startDateString =
                DateFormat('yyyy-MM-dd').format(startOfWeek);
            final endDateString = DateFormat('yyyy-MM-dd').format(endOfWeek);
            dateMatch = (m) =>
                m.date.compareTo(startDateString) >= 0 &&
                m.date.compareTo(endDateString) <= 0;
            break;
          case TrendType.monthly:
            final monthAgo = DateTime(now.year, now.month - (6 - i));
            final firstDayOfMonth = DateTime(monthAgo.year, monthAgo.month, 1);
            final lastDayOfMonth =
                DateTime(monthAgo.year, monthAgo.month + 1, 0);
            final startDateString =
                DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
            final endDateString =
                DateFormat('yyyy-MM-dd').format(lastDayOfMonth);
            dateMatch = (m) =>
                m.date.compareTo(startDateString) >= 0 &&
                m.date.compareTo(endDateString) <= 0;
            break;
        }

        int count = 0;
        for (final m in _medicationController.medications) {
          if (m.userId == currentUserId && dateMatch(m)) {
            count += m.medication.where((med) => med['name'] == type).length;
          }
        }
        countsByType[type]![i] = count;
      }
    }
    return countsByType;
  }

  List<String> _getLabels() {
    final now = DateTime.now();
    switch (selectedTrend) {
      case TrendType.daily:
        return List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          return DateFormat('E').format(day);
        });
      case TrendType.weekly:
        return List.generate(7, (i) {
          final weekStart =
              now.subtract(Duration(days: now.weekday - 1 + 7 * (6 - i)));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return '${DateFormat('d MMM').format(weekStart)}\n${DateFormat('d MMM').format(weekEnd)}';
        });
      case TrendType.monthly:
        return List.generate(7, (i) {
          final monthDate = DateTime(now.year, now.month - (6 - i));
          return DateFormat('MMM').format(monthDate);
        });
    }
  }

  String _determineAdherenceLevel(Map<String, List<int>> countsByType) {
    final allCounts = countsByType.values.expand((x) => x).toList();
    if (allCounts.isEmpty) return "No Data";
    final average = allCounts.reduce((a, b) => a + b) / allCounts.length;
    if (average <= 1) return "Excellent";
    if (average <= 2) return "Good";
    if (average <= 3) return "Fair";
    return "Poor";
  }

  bool isWeek() {
    return selectedTrend == TrendType.weekly;
  }

  String _getFilterDisplayText() {
    if (_selectedFilter == 'Custom Date' &&
        _selectedStartDate != null &&
        _selectedEndDate != null) {
      return '${DateFormat('MMM dd').format(_selectedStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_selectedEndDate!)}';
    }
    return _selectedFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_medicationController.medications.isEmpty) {
        _medicationController.fetchMedications();
      }

      final usage = _calculateUsage();
      final countsByType = _getMedicationCountsByType();
      final types = countsByType.keys.toList();
      final labels = _getLabels();
      final adherence = _determineAdherenceLevel(countsByType);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unified Filter
          if (widget.showFilter) ...[
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication Analysis',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .apply(color: Colors.grey.shade800)
                        .copyWith(fontSize: 18),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date Picker Button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => _selectDateRange(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedFilter == 'Custom Date'
                                  ? TColors.primary
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(TSizes.cardRadiusLg),
                              border: Border.all(
                                color: _selectedFilter == 'Custom Date'
                                    ? TColors.primary
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: _selectedFilter == 'Custom Date'
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _getFilterDisplayText(),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _selectedFilter == 'Custom Date'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      fontWeight:
                                          _selectedFilter == 'Custom Date'
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Period Filter Dropdown
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
                          items: [
                            'Today',
                            'This Week',
                            'This Month',
                            'Custom Date'
                          ].map((String value) {
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
                                if (newValue != 'Custom Date') {
                                  _selectedStartDate = null;
                                  _selectedEndDate = null;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Statistics Cards
          _buildStatisticsCards(),
          const SizedBox(height: TSizes.spaceBtwSections),

          // Medication Usage Analysis
          _buildMedicationUsageAnalysis(),
          const SizedBox(height: TSizes.spaceBtwSections + 15),

          // Chart Section
          _buildChartSection(),
        ],
      );
    });
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
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
                  'Total Medications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: TColors.darkGrey,
                      ),
                ),
                const SizedBox(height: TSizes.sm),
                Text(
                  _getTotalMedications().toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 45,
                      ),
                ),
                if (_selectedFilter == 'Custom Date' &&
                    _selectedStartDate != null &&
                    _selectedEndDate != null) ...[
                  const SizedBox(height: TSizes.xs),
                  Text(
                    '${DateFormat('MMM dd').format(_selectedStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_selectedEndDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TColors.darkGrey,
                          fontSize: 12,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems - 3),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                if (_selectedFilter == 'Custom Date' &&
                    _selectedStartDate != null &&
                    _selectedEndDate != null) ...[
                  const SizedBox(height: TSizes.xs),
                  Text(
                    '${DateFormat('MMM dd').format(_selectedStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_selectedEndDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TColors.darkGrey,
                          fontSize: 12,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationUsageAnalysis() {
    final usage = _calculateUsage();

    return GestureDetector(
      onTap: _navigateToDiaryWithMedicationTab,
      child: Container(
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
          children: [
            Row(
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
                if (_selectedFilter == 'Custom Date' &&
                    _selectedStartDate != null &&
                    _selectedEndDate != null)
                  Text(
                    '${DateFormat('MMM dd').format(_selectedStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_selectedEndDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TColors.darkGrey,
                          fontSize: 12,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ...medications.map((med) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    final countsByType = _getMedicationCountsByType();
    final types = countsByType.keys.toList();
    final labels = _getLabels();
    final adherence = _determineAdherenceLevel(countsByType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medication Usage Trend',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .apply(color: TColors.darkGrey)
                    .copyWith(fontSize: 16),
              ),
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
                child: DropdownButton<TrendType>(
                  value: selectedTrend,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: TrendType.values.map((TrendType type) {
                    return DropdownMenuItem<TrendType>(
                      value: type,
                      child: Text(
                        type == TrendType.daily
                            ? 'Daily'
                            : type == TrendType.weekly
                                ? 'Weekly'
                                : 'Monthly',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (TrendType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedTrend = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: TColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    adherence,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 23),
              SizedBox(
                height: 235,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: types.map((type) {
                        final color = _getColorForMedication(type);
                        final counts = countsByType[type]!;
                        return LineChartBarData(
                          spots: List.generate(
                            counts.length,
                            (i) => FlSpot(i.toDouble(), counts[i].toDouble()),
                          ),
                          isCurved: false,
                          color: color,
                          barWidth: 6,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            reservedSize: 55,
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              int index = value.toInt();
                              if (index >= 0 && index < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Text(
                                    labels[index],
                                    textAlign: TextAlign.center,
                                    style: isWeek()
                                        ? const TextStyle(fontSize: 10)
                                        : const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: selectedTrend == TrendType.daily ? 1 : 10,
                            reservedSize: 35,
                            getTitlesWidget: (value, _) {
                              if (selectedTrend == TrendType.daily) {
                                return Text(value.toInt().toString());
                              } else {
                                if (value % 10 == 0) {
                                  return Text(value.toInt().toString());
                                }
                                return const Text('');
                              }
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Align(
                alignment: Alignment.center,
                child: Text(
                  selectedTrend == TrendType.daily
                      ? 'Days Trend'
                      : selectedTrend == TrendType.weekly
                          ? 'Weekly Trend'
                          : 'Monthly Trend',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (types.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: types.map((type) {
                    final color = _getColorForMedication(type);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(type, style: const TextStyle(fontSize: 13)),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
