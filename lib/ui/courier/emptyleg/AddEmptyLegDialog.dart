import 'package:flutter/material.dart';

import 'EmptyLegMainScreen.dart';

class FlightDetailsDialog extends StatefulWidget {
  final FlightDetails? flightDetails;

  const FlightDetailsDialog({this.flightDetails, Key? key}) : super(key: key);

  @override
  _FlightDetailsDialogState createState() => _FlightDetailsDialogState();
}

class _FlightDetailsDialogState extends State<FlightDetailsDialog> {
  late TextEditingController _fromLocationController;
  late TextEditingController _toLocationController;
  late TextEditingController _fromDateController;
  late TextEditingController _toDateController;
  late TextEditingController _flightNumberController;
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with either passed flight details or empty strings
    _fromLocationController = TextEditingController(text: widget.flightDetails?.fromLocation ?? '');
    _toLocationController = TextEditingController(text: widget.flightDetails?.toLocation ?? '');
    _fromDateController = TextEditingController(text: widget.flightDetails?.fromDate ?? '');
    _toDateController = TextEditingController(text: widget.flightDetails?.toDate ?? '');
    _flightNumberController = TextEditingController(text: widget.flightDetails?.flightNumber ?? '');
    _capacityController = TextEditingController(text: widget.flightDetails?.capacity ?? '');
  }

  @override
  void dispose() {
    // Dispose of controllers when dialog is closed
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _flightNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter Flight Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTextField(_fromLocationController, 'From Location'),
            const SizedBox(height: 10),
            _buildTextField(_toLocationController, 'To Location'),
            const SizedBox(height: 10),
            _buildTextField(_fromDateController, 'From Date'),
            const SizedBox(height: 10),
            _buildTextField(_toDateController, 'To Date'),
            const SizedBox(height: 10),
            _buildTextField(_flightNumberController, 'Flight Number'),
            const SizedBox(height: 10),
            _buildTextField(_capacityController, 'Capacity'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Create new FlightDetails from input
                FlightDetails newDetails = FlightDetails(
                  fromLocation: _fromLocationController.text,
                  toLocation: _toLocationController.text,
                  fromDate: _fromDateController.text,
                  fromTime: '12:00 PM', // Hardcoded for simplicity
                  toDate: _toDateController.text,
                  toTime: '2:00 PM',   // Hardcoded for simplicity
                  flightNumber: _flightNumberController.text,
                  capacity: _capacityController.text,
                  userName: 'User',    // Hardcoded username
                  rating: 5,           // Hardcoded rating
                );

                // Pass data back and close the dialog
                Navigator.of(context).pop(newDetails);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
