import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/utils/DateTimePicker.dart';
import 'EmptyLegMainScreen.dart'; // for formatting date and time

class FlightDetailsDialog extends StatefulWidget {
  final FlightDetails? flightDetails;
  final int? flightIndex;
  final bool isFromBottomSheet; // New parameter to determine how the dialog is opened

  const FlightDetailsDialog({this.flightDetails, this.flightIndex, required this.isFromBottomSheet, Key? key}) : super(key: key);

  @override
  _FlightDetailsDialogState createState() => _FlightDetailsDialogState();
}

class _FlightDetailsDialogState extends State<FlightDetailsDialog> {
  late TextEditingController _fromLocationController;
  late TextEditingController _toLocationController;
  late TextEditingController _fromDateTimeController; // Combined From Date Time
  late TextEditingController _toDateTimeController;   // Combined To Date Time
  late TextEditingController _flightNumberController;
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _fromLocationController = TextEditingController(text: widget.flightDetails?.fromLocation ?? '');
    _toLocationController = TextEditingController(text: widget.flightDetails?.toLocation ?? '');
    _fromDateTimeController = TextEditingController(text: widget.flightDetails?.fromDateTime ?? '');
    _toDateTimeController = TextEditingController(text: widget.flightDetails?.toDateTime ?? '');
    _flightNumberController = TextEditingController(text: widget.flightDetails?.flightNumber ?? '');
    _capacityController = TextEditingController(text: widget.flightDetails?.capacity ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter Flight Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_fromLocationController, 'From Location', false),
              const SizedBox(height: 10),
              _buildTextField(_toLocationController, 'To Location', false),
              const SizedBox(height: 10),
              TextField(
                controller: _fromDateTimeController,
                decoration: InputDecoration(
                  labelText: 'From Date & Time',
                  border: const OutlineInputBorder(),
                ),
                readOnly: true, // Keep this to prevent direct editing
                onTap: () => selectDateTime(context, _fromDateTimeController),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _toDateTimeController,
                decoration: InputDecoration(
                  labelText: 'To Date & Time',
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => selectDateTime(context, _toDateTimeController),
              ),
              const SizedBox(height: 10),
              _buildTextField(_flightNumberController, 'Flight Number', false),
              const SizedBox(height: 10),
              _buildTextField(_capacityController, 'Capacity', false),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (widget.isFromBottomSheet)
                    ElevatedButton(
                      onPressed: () {
                        FlightDetails updatedDetails = FlightDetails(
                          fromLocation: _fromLocationController.text,
                          toLocation: _toLocationController.text,
                          fromDateTime: _fromDateTimeController.text,
                          toDateTime: _toDateTimeController.text,
                          flightNumber: _flightNumberController.text,
                          capacity: _capacityController.text,
                          userName: 'User',
                          rating: 5,
                        );
                        Navigator.of(context).pop({'action': 'update', 'details': updatedDetails, 'index': widget.flightIndex});
                      },
                      child: const Text('Update'),
                    ),
                  if (widget.isFromBottomSheet && widget.flightIndex != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({'action': 'delete', 'index': widget.flightIndex});
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  if (!widget.isFromBottomSheet)
                    ElevatedButton(
                      onPressed: () {
                        FlightDetails newDetails = FlightDetails(
                          fromLocation: _fromLocationController.text,
                          toLocation: _toLocationController.text,
                          fromDateTime: _fromDateTimeController.text,
                          toDateTime: _toDateTimeController.text,
                          flightNumber: _flightNumberController.text,
                          capacity: _capacityController.text,
                          userName: 'User',
                          rating: 5,
                        );
                        Navigator.of(context).pop({'action': 'save', 'details': newDetails});
                      },
                      child: const Text('Save'),
                    ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, bool isReadOnly) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      readOnly: isReadOnly,
    );
  }
}
