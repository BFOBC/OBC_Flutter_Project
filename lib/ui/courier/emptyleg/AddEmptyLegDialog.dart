import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/utils/CustomDialog.dart';
import '../../common/utils/DateTimePicker.dart';
import 'EmptyLegMainScreen.dart';

class FlightDetailsDialog extends StatefulWidget {
  final FlightDetails? flightDetails;
  final int? flightIndex;
  final bool isFromBottomSheet;

  const FlightDetailsDialog({this.flightDetails, this.flightIndex, required this.isFromBottomSheet, super.key});

  @override
  _FlightDetailsDialogState createState() => _FlightDetailsDialogState();
}

class _FlightDetailsDialogState extends State<FlightDetailsDialog> {
  late TextEditingController _fromLocationController;
  late TextEditingController _toLocationController;
  late TextEditingController _fromDateTimeController;
  late TextEditingController _toDateTimeController;
  late TextEditingController _flightNumberController;
  late TextEditingController _capacityController;

  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    _fromLocationController =
        TextEditingController(text: widget.flightDetails?.fromLocation ?? '');
    _toLocationController =
        TextEditingController(text: widget.flightDetails?.toLocation ?? '');
    _fromDateTimeController =
        TextEditingController(text: widget.flightDetails?.fromDateTime ?? '');
    _toDateTimeController =
        TextEditingController(text: widget.flightDetails?.toDateTime ?? '');
    _flightNumberController =
        TextEditingController(text: widget.flightDetails?.flightNumber ?? '');
    _capacityController =
        TextEditingController(text: widget.flightDetails?.capacity ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        clipBehavior: Clip.none,
        // Allow the stack to overflow for the close button
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey, // Assign form key
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add New Job', style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors
                                  .blue, // Blue circle background color
                            ),
                            child: Icon(
                                Icons.close, color: Colors.white), // Close icon
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_fromLocationController, 'From Location'),
                    const SizedBox(height: 10),
                    _buildTextField(_toLocationController, 'To Location'),
                    const SizedBox(height: 10),
                    _buildDateTimeField(
                        _fromDateTimeController, 'From Date & Time'),
                    const SizedBox(height: 10),
                    _buildDateTimeField(
                        _toDateTimeController, 'To Date & Time'),
                    const SizedBox(height: 10),
                    _buildTextField(_flightNumberController, 'Flight Number'),
                    const SizedBox(height: 10),
                    _buildTextField(_capacityController, 'Capacity'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.isFromBottomSheet)
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
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
                                CustomDialog.showCustomDialog2(
                                    context, "Job Updated");
                                Future.delayed(Duration(seconds: 2), () {
                                  Navigator.of(context).pop({
                                    'action': 'update',
                                    'details': updatedDetails,
                                    'index': widget.flightIndex
                                  });
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              // Change button color to blue
                              foregroundColor: Colors
                                  .white, // Change text color to white
                            ),
                            child: const Text('Update'),
                          ),
                        if (!widget.isFromBottomSheet)
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
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
                                CustomDialog.showCustomDialog2(
                                    context, "Job Added");
                                Future.delayed(Duration(seconds: 2), () {
                                  Navigator.of(context).pop({
                                    'action': 'save',
                                    'details': newDetails
                                  });
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              // Change button color to blue
                              foregroundColor: Colors
                                  .white, // Change text color to white
                            ),
                            child: const Text('Save'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build text field with validation logic
  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$labelText is required';
        }
        if ((labelText == 'From Location' || labelText == 'To Location') &&
            value.length != 3) {
          return '$labelText must be exactly 3 characters';
        }
        return null;
      },
    );
  }

  // Build date time field with date restrictions
  Widget _buildDateTimeField(TextEditingController controller,
      String labelText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      readOnly: true,
      onTap: () => selectDateTime(context, controller),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$labelText is required';
        }
        return null;
      },
    );
  }

  Future<void> selectDateTime(BuildContext context,
      TextEditingController controller) async {
    DateTime now = DateTime.now();

    // Pick date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month + 6),
    );

    if (pickedDate != null) {
      // Pick time
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (pickedTime != null) {
        // Combine date and time
        DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(
            combinedDateTime);
        setState(() {
          controller.text = formattedDateTime; // Save combined date and time
        });
      }
    }
  }
}