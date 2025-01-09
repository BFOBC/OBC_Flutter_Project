import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';

class ViewJob extends StatefulWidget {
  const ViewJob({Key? key}) : super(key: key);

  @override
  _ViewJobState createState() => _ViewJobState();
}

class _ViewJobState extends State<ViewJob> {
  final TextEditingController _startDateTimeController = TextEditingController();
  final TextEditingController _endDateTimeController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  final TextEditingController _bidController = TextEditingController();
  final TextEditingController _flightNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    final firestoreService = FirestoreService(context);

    try {
      final querySnapshot = await firestoreService.getJobsByCourierID();

      if (querySnapshot.isNotEmpty) {
        final EmptyLegRequest job = EmptyLegRequest.fromMap(querySnapshot.first.values as Map<String, dynamic>);
        _populateFields(job);
      }
    } catch (error) {
      debugPrint('Error fetching job details: $error');
    }
  }

  void _populateFields(EmptyLegRequest job) {
    _startDateTimeController.text = job.startTimeDate ?? '';
    _endDateTimeController.text = job.endTimeDate ?? '';
    _departureController.text = job.departureLocation ?? '';
    _arrivalController.text = job.arrivalLocation ?? '';
    _bidController.text = job.bid ?? '';
    //_flightNumberController.text = job.flightNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Job')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField('Start Time And Date', _startDateTimeController, true),
              _buildTextField('End Time And Date', _endDateTimeController, true),
              _buildTextField('Departure Location', _departureController, false),
              _buildTextField('Arrival Location', _arrivalController, false),
              _buildTextField('Bid', _bidController, false),
            //  _buildTextField('Flight Number', _flightNumberController, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isReadOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onTap: isReadOnly ? () => _selectDateAndTime(controller) : null,
      ),
    );
  }

  Future<void> _selectDateAndTime(TextEditingController controller) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        final DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        controller.text = selectedDateTime.toLocal().toString();
      }
    }
  }

}
