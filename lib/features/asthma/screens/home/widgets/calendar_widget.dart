import 'package:asthma_app/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:asthma_app/features/asthma/controllers/selected_date_controller.dart';

class TCalendarWidget extends StatefulWidget {
  const TCalendarWidget({super.key});

  @override
  State<TCalendarWidget> createState() => _TCalendarWidgetState();
}

class _TCalendarWidgetState extends State<TCalendarWidget> {
  final ScrollController _scrollController = ScrollController();
  final double _itemWidth =
      72.0; // 60px width + 12px padding (6px on each side)

  @override
  void initState() {
    super.initState();
    // Schedule the scroll after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    // Calculate the position to center today's date
    // We have 12 items before today (index 12 is today)
    final double offset =
        12 * _itemWidth - (MediaQuery.of(context).size.width - _itemWidth) / 2;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final List<DateTime> dateList =
        List.generate(15, (i) => today.add(Duration(days: i - 12)));
    final selectedDateController = Get.find<SelectedDateController>();

    return Obx(() {
      final selectedDate = selectedDateController.selectedDate;

      return SizedBox(
        height: 70,
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          itemCount: dateList.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, index) {
            final date = dateList[index];
            final dayNumber = DateFormat('d').format(date);
            final dayName = DateFormat('E').format(date);
            final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                DateFormat('yyyy-MM-dd').format(selectedDate);
            final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                DateFormat('yyyy-MM-dd').format(today);

            // Determine colors based on selection and today status
            Color backgroundColor;
            Color textColor;
            Border? border;
            List<BoxShadow>? shadows;

            if (isToday) {
              // Today's date always has white background and blue text
              backgroundColor = Colors.white;
              textColor = TColors.primary;
              border = Border.all(
                  color: TColors.primary.withOpacity(0.3), width: 1.5);
              shadows = [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ];
            } else if (isSelected) {
              backgroundColor = TColors.primary;
              textColor = Colors.white;
              border = Border.all(color: Colors.white, width: 2);
              shadows = [
                BoxShadow(
                  color: TColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ];
            } else {
              backgroundColor = Colors.white.withOpacity(0.1);
              textColor = Colors.white.withOpacity(0.7);
              border = Border.all(color: Colors.transparent, width: 2);
              shadows = [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                ),
              ];
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () {
                  selectedDateController.setSelectedDate(date);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: shadows,
                    border: border,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayNumber,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
