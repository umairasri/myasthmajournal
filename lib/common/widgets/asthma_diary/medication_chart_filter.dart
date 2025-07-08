import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:asthma_app/features/asthma/controllers/medication_controller.dart';
import 'package:asthma_app/features/personalization/controllers/selected_dependent_controller.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:asthma_app/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:asthma_app/features/asthma/models/medication_model.dart';

enum TrendType { daily, weekly, monthly }

class MedicationChartFilter extends StatefulWidget {
  const MedicationChartFilter({super.key});

  @override
  State<MedicationChartFilter> createState() => _MedicationChartFilterState();
}

class _MedicationChartFilterState extends State<MedicationChartFilter> {
  final MedicationController _medicationController = Get.find();
  final SelectedDependentController _selectedDependentController = Get.find();
  TrendType selectedTrend = TrendType.daily;

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
        // Count medications of this type for this period
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
    // Sum all counts for all types
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final countsByType = _getMedicationCountsByType();
      final types = countsByType.keys.toList();
      final labels = _getLabels();
      final adherence = _determineAdherenceLevel(countsByType);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Chart Title with Filter
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

          /// -- Body Chart
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
                    /// Chart Stroke Color (use primary for adherence indicator)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: TColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 10),

                    /// Adherence Indicator
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
                              interval:
                                  selectedTrend == TrendType.daily ? 1 : 10,
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
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
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
                // Legend
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
    });
  }
}
