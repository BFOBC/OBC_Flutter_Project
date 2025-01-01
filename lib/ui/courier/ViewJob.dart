import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:flutter/material.dart';

class ViewJob extends StatefulWidget {
  final Task? data; // The Task object received
  const ViewJob({super.key, this.data});

  @override
  _ViewJobState createState() => _ViewJobState();
}

class _ViewJobState extends State<ViewJob> {
  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  final TextEditingController _field3Controller = TextEditingController();
  final TextEditingController _field4Controller = TextEditingController();
  final TextEditingController _field5Controller = TextEditingController();
  final TextEditingController _fieldBidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Populate fields if data is not null
    if (widget.data != null) {
      _field1Controller.text = widget.data!.startDateTime!; // Start Time And Date
      _field2Controller.text = widget.data!.endDateTime!;   // End Time And Date
      _field3Controller.text = widget.data!.departureFrom!; // Departure Location
      _field4Controller.text = widget.data!.arriveAt!;      // Arrival Location
      _fieldBidController.text = widget.data!.bid!;         // Bid
      _field5Controller.text = widget.data!.flightNumber!;   // Flight Number
    }
  }

  bool validate() {
    bool isValid = true;
    String errorMessage = '';

    if (_field1Controller.text.isEmpty) {
      isValid = false;
      errorMessage += 'Start Time And Date is required.\n';
    }
    if (_field2Controller.text.isEmpty) {
      isValid = false;
      errorMessage += 'End Time And Date is required.\n';
    }
    if (_field3Controller.text.isEmpty) {
      isValid = false;
      errorMessage += 'Departure Location is required.\n';
    }
    if (_field4Controller.text.isEmpty) {
      isValid = false;
      errorMessage += 'Arrival Location is required.\n';
    }
    if (_fieldBidController.text.isEmpty) {
      isValid = false;
      errorMessage += 'Bid is required.\n';
    }
    if (_field5Controller.text.isEmpty) {
      isValid = false;
      errorMessage += 'Flight Number is required.\n';
    }
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _field1Controller,
              decoration: const InputDecoration(
                labelText: 'Start Time And Date',
                border: OutlineInputBorder(),
              ),
              onTap: () => _selectDateAndTime(_field1Controller),
              readOnly: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _field2Controller,
              decoration: const InputDecoration(
                labelText: 'End Time And Date',
                border: OutlineInputBorder(),
              ),
              onTap: () => _selectDateAndTime(_field2Controller),
              readOnly: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _field3Controller,
              decoration: const InputDecoration(
                labelText: 'Departure Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _field4Controller,
              decoration: const InputDecoration(
                labelText: 'Arrival Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fieldBidController,
              decoration: const InputDecoration(
                labelText: 'Bid',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _field5Controller,
              decoration: const InputDecoration(
                labelText: 'Courier Capacity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateAndTime(TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        String formattedDateTime = '${"${selectedDateTime.toLocal()}".split(' ')[0]} ${selectedDateTime.toLocal().toIso8601String().split('T')[1].split('.')[0]}';
        controller.text = formattedDateTime;
      }
    }
  }
}
