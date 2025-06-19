import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SelectedDateController extends GetxController {
  final Rx<DateTime> _selectedDate = DateTime.now().obs;

  DateTime get selectedDate => _selectedDate.value;

  void setSelectedDate(DateTime date) {
    if (_selectedDate.value.year != date.year ||
        _selectedDate.value.month != date.month ||
        _selectedDate.value.day != date.day) {
      _selectedDate.value = date;
      update();
    }
  }

  void resetToToday() {
    final now = DateTime.now();
    if (_selectedDate.value.year != now.year ||
        _selectedDate.value.month != now.month ||
        _selectedDate.value.day != now.day) {
      _selectedDate.value = now;
      update();
    }
  }

  String get formattedDate =>
      DateFormat('yyyy-MM-dd').format(_selectedDate.value);

  bool isToday() {
    final now = DateTime.now();
    return _selectedDate.value.year == now.year &&
        _selectedDate.value.month == now.month &&
        _selectedDate.value.day == now.day;
  }
}
