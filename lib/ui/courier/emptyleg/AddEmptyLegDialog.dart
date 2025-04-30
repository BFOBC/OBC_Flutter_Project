import 'dart:convert';
import 'package:broker_flutter_pp/data/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
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
  AirportModel? selectedFromAirport;
  AirportModel? selectedToAirport;

  FlightDetailsDialog({
    this.flightDetails,
    this.flightIndex,
    required this.isFromBottomSheet,
    super.key,
  });

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

  final _formKey = GlobalKey<FormState>();
  final CollectionReference emptyLegCollection = FirebaseFirestore.instance.collection('emptyLegs');

  List<AirportModel> fromAirportSuggestions = []; // Suggestions for "From Location"
  List<AirportModel> toAirportSuggestions = []; // Suggestions for "To Location"

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

  Future<void> _saveToFirStore() async {
    try {
      String fromDateTime=(convertToUTCFromCustomFormat(_fromDateTimeController.text.toString()));
      String toDateTime=(convertToUTCFromCustomFormat(_toDateTimeController.text.toString()));
      String courierID = getCurrentUserId();
      await FirebaseFirestore.instance.collection('emptyLegs').add({
        'fromLocation': _fromLocationController.text,
        'toLocation': _toLocationController.text,
        'fromDateTime': fromDateTime,
        'toDateTime': toDateTime,
        'flightNumber': _flightNumberController.text,
        'capacity': _capacityController.text,
        'createdAt': DateTime.now().toIso8601String(),
        'courierID': courierID
      });
      // Close the dialog after saving
      Navigator.of(context).pop(); // This will close the dialog
      CustomDialog.showCustomDialog2(context, "Empty Leg Added Successfully");
    } catch (e) {
      CustomDialog.showCustomDialog2(context, "Error: ${e.toString()}");
    }
  }

  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  }

  // Fetch airports that match the query for From Location
  Future<void> _fetchFromAirportData(String query) async {
    if (query.isNotEmpty) {
      try {
        final airports = await fetchAirportsFromDatabase(query);
        setState(() {
          fromAirportSuggestions = airports;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching airports: $e')));
      }
    } else {
      setState(() {
        fromAirportSuggestions = [];
      });
    }
  }

  // Fetch airports that match the query for To Location
  Future<void> _fetchToAirportData(String query) async {
    if (query.isNotEmpty) {
      try {
        final airports = await fetchAirportsFromDatabase(query);
        setState(() {
          toAirportSuggestions = airports;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching airports: $e')));
      }
    } else {
      setState(() {
        toAirportSuggestions = [];
      });
    }
  }

  Future<List<AirportModel>> fetchAirportsFromDatabase(String query) async {
    final dbHelper = DatabaseOperation();
    try {
      List<AirportModel> airports = await dbHelper.fetchAirportsFromDatabase(query);
      return airports;
    } catch (e) {
      print('Error _fetchAirports $e');
      return [];
    }
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {ValueChanged<String>? onChanged, ValueChanged<String>? onFieldSubmitted}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$labelText is required';
        }
        return null;
      },
    );
  }

 @override
    Widget build(BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.zero, // Removes padding around the dialog
        backgroundColor: Colors.transparent, // Makes the dialog background transparent
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity, // Makes the dialog take full screen height
              color: Colors.white, // Or any color you prefer for the background
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Your existing dialog content here (form, fields, buttons, etc.)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Add New Job', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _fromLocationController,
                        'From Location',
                        onChanged: (value) => _fetchFromAirportData(value),
                      ),
                      // Show suggestions below 'From Location'
                      if (fromAirportSuggestions.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: fromAirportSuggestions.length,
                          itemBuilder: (context, index) {
                            final airport = fromAirportSuggestions[index];
                            return ListTile(
                              title: Text(airport.name ?? 'Unknown'),
                              onTap: () {
                                setState(() {
                                  _fromLocationController.text = airport.name ?? '';
                                  widget.selectedFromAirport = airport;
                                  fromAirportSuggestions = [];
                                });
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _toLocationController,
                        'To Location',
                        onChanged: (value) => _fetchToAirportData(value),
                      ),
                      // Show suggestions below 'To Location'
                      if (toAirportSuggestions.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: toAirportSuggestions.length,
                          itemBuilder: (context, index) {
                            final airport = toAirportSuggestions[index];
                            return ListTile(
                              title: Text(airport.name ?? 'Unknown'),
                              onTap: () {
                                setState(() {
                                  _toLocationController.text = airport.name ?? '';
                                  widget.selectedToAirport = airport;
                                  toAirportSuggestions = [];
                                });
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 10),
                      _buildDateTimeField(_fromDateTimeController, 'From Date & Time'),
                      const SizedBox(height: 10),
                      _buildDateTimeField(_toDateTimeController, 'To Date & Time'),
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
                                  CustomDialog.showCustomDialog2(context, "Job Updated");
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
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Update'),
                            ),
                          if (!widget.isFromBottomSheet)
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _saveToFirStore();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
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

  // Build date time field with date restrictions
  Widget _buildDateTimeField(TextEditingController controller, String labelText) {
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

  Future<void> selectDateTime(BuildContext context, TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime selectedDate = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (pickedTime != null) {
        selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        controller.text = formatter.format(selectedDate);
      }
    }
  }
}

