import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:asthma_app/common/widgets/asthma_diary/symptom_chart_filter.dart';
import 'package:asthma_app/common/widgets/asthma_diary/symptom_statistics_cards.dart';
import 'package:asthma_app/common/widgets/asthma_diary/symptom_type_bar_chart.dart';
import 'package:asthma_app/common/widgets/asthma_diary/symptom_pie_chart.dart';
import 'package:asthma_app/utils/constants/sizes.dart';

class UnifiedSymptomAnalysis extends StatefulWidget {
  const UnifiedSymptomAnalysis({super.key});

  @override
  State<UnifiedSymptomAnalysis> createState() => _UnifiedSymptomAnalysisState();
}

class _UnifiedSymptomAnalysisState extends State<UnifiedSymptomAnalysis> {
  String _selectedFilter = 'Today';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (startDate != null) {
      final DateTime? endDate = await showDatePicker(
        context: context,
        initialDate: _selectedEndDate ?? startDate,
        firstDate: startDate,
        lastDate: DateTime.now(),
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title for Symptom Analysis
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text(
                'Symptom Analysis',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .apply(color: Colors.grey.shade800)
                    .copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 8),
            // Unified filter for the next three sections
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedFilter == 'Custom Date'
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(TSizes.cardRadiusLg),
                        border: Border.all(
                          color: _selectedFilter == 'Custom Date'
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 120,
                            child: Text(
                              _getFilterDisplayText(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedFilter == 'Custom Date'
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: _selectedFilter == 'Custom Date'
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
                    items: ['Today', 'This Week', 'This Month', 'Custom Date']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black),
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
            const SizedBox(height: TSizes.spaceBtwSections),
            // 2. Symptom Statistics Cards
            SymptomStatisticsCards(
              filter: _selectedFilter,
              startDate: _selectedStartDate,
              endDate: _selectedEndDate,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            // 3. Symptom Type Bar Chart
            SymptomTypeBarChart(
              filter: _selectedFilter,
              startDate: _selectedStartDate,
              endDate: _selectedEndDate,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            // 4. Symptom Pie Chart
            SymptomPieChart(
              filter: _selectedFilter,
              startDate: _selectedStartDate,
              endDate: _selectedEndDate,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            // 1. Symptom Statistic Trend (keep its own filter)
            const SymptomChartFilter(),
          ],
        ),
      ),
    );
  }
}
