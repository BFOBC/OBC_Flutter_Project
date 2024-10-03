import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> selectDateTime(BuildContext context, TextEditingController controller) async {
  // First, pick the date
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (pickedDate != null) {
    // If a date was picked, proceed to pick the time
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // Combine the picked date and time
      DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
      String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);

      // Update the TextEditingController with the formatted date and time
      controller.text = formattedDateTime;
    }
  }
}
void showSnackBar(BuildContext ctx,String message) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
