import 'dart:convert';

import 'package:broker_flutter_pp/data/DatabaseOperation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../data/DatabaseHelper.dart';
import '../../common/utils/CustomDialog.dart';
import '../../common/utils/DateTimePicker.dart';
import 'EmptyLegMainScreen.dart';

class FlightDetailsDialog extends StatefulWidget {
  final FlightDetails? flightDetails;
  final int? flightIndex;
  final bool isFromBottomSheet;
  List<Map<String, dynamic>> airportData = []; // To store airport items matching the query
  Map<String, dynamic>? selectedFromAirport;
  Map<String, dynamic>? selectedToAirport;
  FlightDetailsDialog({this.flightDetails, this.flightIndex, required this.isFromBottomSheet, super.key});

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
  final CollectionReference emptyLegCollection = FirebaseFirestore.instance.collection('emptyLegs');

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

  Future<void> _saveToFirStore() async {
  try {
    String courierID=getCurrentUserId();
    await FirebaseFirestore.instance.collection('emptyLegs').add({
      'fromLocation': _fromLocationController.text,
      'toLocation': _toLocationController.text,
      'fromDateTime': _fromDateTimeController.text,
      'toDateTime': _toDateTimeController.text,
      'flightNumber': _flightNumberController.text,
      'capacity': _capacityController.text,
      'createdAt': DateTime.now().toIso8601String(),
      'courierID':courierID
    });
    CustomDialog.showCustomDialog2(context, "Empty Leg Added Successfully");
  } catch (e) {
    CustomDialog.showCustomDialog2(context, "Error: ${e.toString()}");
  }
}
  String getCurrentUserId() {
    // Replace this with your actual logic to retrieve the user ID
    return FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  }
  Widget _buildAutoCompleteField(
      TextEditingController controller,
      String labelText,
      Function(Map<String, dynamic>) onSelectedAirport,
      ) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (Map<String, dynamic> option) => option['gps_code'], // Display gps_code
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }

        try {
          // Fetch airports matching the query
          final results = await _fetchAirportsByGpsCode(textEditingValue.text);
          if (results.isEmpty) {
            // Show SnackBar if no results
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No results found for "${textEditingValue.text}"'),
              ),
            );
          }
          return results;
        } catch (e) {
          // Show SnackBar if error occurs
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error fetching model: $e'),
            ),
          );
          return [];
        }
      },
      onSelected: (Map<String, dynamic> selection) {
        onSelectedAirport(selection); // Pass the selected airport item
        controller.text = selection['gps_code']; // Display gps_code in the field
      },
      fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }
  Future<List<Map<String, dynamic>>> _fetchAirportsByGpsCode(String query) async {
    //final dbHelper = DatabaseHelper(); // Replace with your actual DB helper class
    final dbHelper = DatabaseOperation();
    return await dbHelper.fetchAirportsByGpsCode(query);
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors
                                  .blue, // Blue circle background color
                            ),
                            child: const Icon(
                                Icons.close, color: Colors.white), // Close icon
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildAutoCompleteField(
                      _fromLocationController,
                      'From Location',
                          (selectedAirport) => widget.selectedFromAirport = selectedAirport,
                    ),

                    //_buildTextField(_fromLocationController, 'From Location'),
                    const SizedBox(height: 10),
                    _buildAutoCompleteField(
                      _toLocationController,
                      'To Location',
                          (selectedAirport) => widget.selectedToAirport = selectedAirport,
                    ),

                   // _buildTextField(_toLocationController, 'To Location'),
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
                                Future.delayed(const Duration(seconds: 2), () {
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
                                // Instead of manually creating FlightDetails, directly call _saveToFirestore// 
                                _saveToFirStore();
                                }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Change button color to blue
                                  foregroundColor: Colors.white, // Change text color to white
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
  Widget buildGpsCodeField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      inputFormatters: [
        LengthLimitingTextInputFormatter(4), // Limit to 4 characters
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), // Allow alphanumeric input
      ],
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters, // Automatically capitalize input
      validator: (value) {
        if (value == null || value.length != 4) {
          return 'GPS code must be 4 characters.';
        }
        return null;
      },
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