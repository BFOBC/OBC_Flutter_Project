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
String getCurrentTimeInUTC() {
  final now = DateTime.now(); // System/local time
  final utcTime = now.toUtc(); // Convert to UTC
  return utcTime.toIso8601String(); // Return ISO 8601 formatted string
}
String convertUTCToLocal(String utcTimeString) {
  final utcTime = DateTime.parse(utcTimeString).toUtc(); // Ensure it's UTC
  final localTime = utcTime.toLocal(); // Convert to local time
  return localTime.toString(); // Or use toIso8601String() if needed
}
String convertToUTCFromCustomFormat(String dateTimeString) {
  try {
    // Parse the input string into a DateTime object (local time)
    DateTime localTime = DateTime.parse(dateTimeString.replaceAll(' ', 'T') + ':00'); // Adding seconds part

    // Convert the DateTime to UTC
    DateTime utcTime = localTime.toUtc();

    // Return the UTC time in ISO 8601 format
    return utcTime.toIso8601String();
  } catch (e) {
    return "Invalid Date Format"; // Handle invalid format
  }
}
