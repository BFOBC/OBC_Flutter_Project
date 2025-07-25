import 'dart:convert';
import 'package:broker_flutter_pp/data/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/widgets/NoLeadingZeroFormatter.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/JobCardStackWidget.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/UpperCaseTextFormatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../data/DatabaseHelper.dart';
import '../../common/utils/CustomDialog.dart';
import '../../common/utils/DateTimePicker.dart';
import 'EmptyLegMainScreen.dart';

class FlightDetailsDialog extends StatefulWidget {
  final FlightDetails? flightDetails;
  final int? flightIndex;
  final bool isUpdate;
  final String? emptyLegID;
  List<Map<String, dynamic>> airportData =
      []; // To store airport items matching the query
  AirportModel? selectedFromAirport;
  AirportModel? selectedToAirport;

  FlightDetailsDialog({
    this.flightDetails,
    this.flightIndex,
    required this.isUpdate,
    required this.emptyLegID,
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
  final CollectionReference emptyLegCollection =
      FirebaseFirestore.instance.collection('emptyLegs');

  List<AirportModel> fromAirportSuggestions =
      []; // Suggestions for "From Location"
  List<AirportModel> toAirportSuggestions = []; // Suggestions for "To Location"
  final DateFormat inputFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ");
  final DateFormat outputFormat = DateFormat("yyyy-MM-dd HH:mm");

  @override
  void initState() {
    super.initState();
    _fromLocationController =
        TextEditingController(text: widget.flightDetails?.fromLocation ?? '');
    _toLocationController =
        TextEditingController(text: widget.flightDetails?.toLocation ?? '');
    //_fromDateTimeController = TextEditingController(text: widget.flightDetails?.fromDateTime ?? '');
    //_toDateTimeController = TextEditingController(text: widget.flightDetails?.toDateTime ?? '');
    _flightNumberController =
        TextEditingController(text: widget.flightDetails?.flightNumber ?? '');
    _capacityController =
        TextEditingController(text: widget.flightDetails?.capacity ?? '');
    // Inside initState or where you're assigning:
    _fromDateTimeController = TextEditingController(
      text: formatDate(widget.flightDetails?.fromDateTime),
    );

    _toDateTimeController = TextEditingController(
      text: formatDate(widget.flightDetails?.toDateTime),
    );
  }

  String formatDate(String? utcString) {
    if (utcString == null || utcString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(utcString).toLocal(); // Convert to local
      return outputFormat.format(dateTime);
    } catch (e) {
      return '';
    }
  }

  Future<void> _saveToFirStore() async {
    try {
      String fromDateTime = (convertToUTCFromCustomFormat(
          _fromDateTimeController.text.toString()));
      String toDateTime =
          (convertToUTCFromCustomFormat(_toDateTimeController.text.toString()));
      String courierID = getCurrentUserId();
      final docRef =
          await FirebaseFirestore.instance.collection('emptyLegs').add({
        'fromLocation': _fromLocationController.text,
        'toLocation': _toLocationController.text,
        'fromDateTime': fromDateTime,
        'toDateTime': toDateTime,
        'flightNumber': _flightNumberController.text,
        'capacity': _capacityController.text,
        'createdAt': DateTime.now().toIso8601String(),
        'courierID': courierID,
        'status': 'new'
      });

// This is your Firestore Document ID (NodeID)
      final String nodeId = docRef.id;

// Optionally save it back to the same document
      await FirebaseFirestore.instance
          .collection('emptyLegs')
          .doc(nodeId)
          .update({
        'emptyLegNodeID': nodeId,
      });

      // Close the dialog after saving
      Navigator.of(context).pop(); // This will close the dialog
      CustomDialog.showCustomDialog2(context, "Empty Leg Added Successfully");
    } catch (e) {
      CustomDialog.showCustomDialog2(context, "Error: ${e.toString()}");
    }
  }

  Future<void> _updateInFireStore(String documentId) async {
    try {
      String fromDateTime =
          convertToUTCFromCustomFormat(_fromDateTimeController.text.toString());
      String toDateTime =
          convertToUTCFromCustomFormat(_toDateTimeController.text.toString());
      String courierID = getCurrentUserId();

      await FirebaseFirestore.instance
          .collection('emptyLegs')
          .doc(documentId)
          .update({
        'fromLocation': _fromLocationController.text,
        'toLocation': _toLocationController.text,
        'fromDateTime': fromDateTime,
        'toDateTime': toDateTime,
        'flightNumber': _flightNumberController.text,
        'capacity': _capacityController.text,
        'courierID': courierID,
        'updatedAt': DateTime.now().toIso8601String(),
        'status': 'new'
      });

      Navigator.of(context).pop(); // Close the dialog
    } catch (e) {
      CustomDialog.showCustomDialog2(context, "Error: ${e.toString()}");
    }
  }

  Future<void> _updateFlightDetails() async {
    FlightDetails updatedDetails = FlightDetails(
      fromLocation: _fromLocationController.text,
      toLocation: _toLocationController.text,
      fromDateTime: _fromDateTimeController.text,
      toDateTime: _toDateTimeController.text,
      flightNumber: _flightNumberController.text,
      capacity: _capacityController.text,
      rating: 5, // Or from any control
    );

    CustomDialog.showCustomDialog2(context, "Job Updated");
    // Return data back to caller
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop({
        'action': 'update',
        'details': updatedDetails,
        'index': widget.flightIndex,
      });
    });
    await _updateInFireStore(widget.emptyLegID!);
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching airports: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching airports: $e')));
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
      List<AirportModel> airports =
          await dbHelper.fetchAirportsFromDatabase(query);
      return airports;
    } catch (e) {
      print('Error _fetchAirports $e');
      return [];
    }
  }

/*  Widget _buildTextField(
      TextEditingController controller,
      String labelText, {
        ValueChanged<String>? onChanged,
        ValueChanged<String>? onFieldSubmitted,
        List<TextInputFormatter>? inputFormatters, // ✅ Add this
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters, // ✅ Use it here
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$labelText is required';
        }
        return null;
      },
    );
  }*/
  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text, // ✅ Default to text
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      // ✅ Use it here
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
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
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
        child: SafeArea(
          child: Column(
            children: [
              /// Top AppBar-style Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32), // Placeholder for alignment
                  Text(
                    widget.isUpdate ? 'Update Job' : 'Add New Job',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 70),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              /// Body Form
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildStyledField(
                          child: _buildTextField(
                            _fromLocationController,
                            'From Location',
                            onChanged: (value) {
                              if (value.length == 3)
                                _fetchFromAirportData(value);
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(3),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z]')),
                              // Allow both lowercase and uppercase
                              UpperCaseTextFormatter(),
                              // Convert to uppercase automatically
                            ],
                          ),
                        ),
                        _buildSuggestionList(
                            fromAirportSuggestions, _fromLocationController,
                            isFrom: true),

                        _buildStyledField(
                          child: _buildTextField(
                            _toLocationController,
                            'To Location',
                            onChanged: (value) {
                              if (value.length == 3) _fetchToAirportData(value);
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(3),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z]')),
                              // Allow both lowercase and uppercase
                              UpperCaseTextFormatter(),
                              // Convert to uppercase automatically
                            ],
                          ),
                        ),
                        _buildSuggestionList(
                            toAirportSuggestions, _toLocationController,
                            isFrom: false),

                        _buildStyledField(
                            child: _buildDateTimeField(
                                _fromDateTimeController, 'From Date & Time')),
                        _buildStyledField(
                            child: _buildDateTimeField(
                                _toDateTimeController, 'To Date & Time')),
                        _buildStyledField(
                            child: _buildTextField(
                                _flightNumberController, 'Flight Number')),
                        _buildStyledField(
                          child: _buildTextField(
                            _capacityController,
                            'Capacity',
                            keyboardType: TextInputType.number,
                            // ✅ Set numeric keyboard
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              NoLeadingZeroFormatter(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// Save / Update Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.7, // 80% width of screen
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final dateFormat =
                                        DateFormat('yyyy-MM-dd HH:mm');
                                    final fromText =
                                        _fromDateTimeController.text.trim();
                                    final toText =
                                        _toDateTimeController.text.trim();

                                    print("🔍 From Date Controller: $fromText");
                                    print("🔍 To Date Controller:   $toText");

                                    try {
                                      final fromDate =
                                          dateFormat.parseStrict(fromText);
                                      final toDate =
                                          dateFormat.parseStrict(toText);

                                      print("✅ Parsed From Date: $fromDate");
                                      print("✅ Parsed To Date:   $toDate");

                                      if (!toDate.isAfter(fromDate)) {
                                        Fluttertoast.showToast(
                                          msg:
                                              "❌ To Date must be greater than From Date.",
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white,
                                          gravity: ToastGravity.BOTTOM,
                                        );
                                        return;
                                      }
                                      if (widget.isUpdate) {
                                        _updateFlightDetails(); // <-- separated method
                                      } else {
                                        _saveToFirStore();
                                      }
                                    } catch (e) {
                                      print("❗ Date parsing failed: $e");

                                      Fluttertoast.showToast(
                                        msg:
                                            "❌ Invalid date format. Please reselect the dates.",
                                        backgroundColor: Colors.red,
                                        textColor: Colors.white,
                                        gravity: ToastGravity.TOP,
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  widget.isUpdate ? 'Update' : 'Save',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildStyledField({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSuggestionList(
      List<AirportModel> suggestions, TextEditingController controller,
      {required bool isFrom}) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final airport = suggestions[index];
        return ListTile(
          title: Text(airport.name ?? 'Unknown'),
          onTap: () {
            setState(() {
              controller.text = airport.name ?? '';
              if (isFrom) {
                widget.selectedFromAirport = airport;
                fromAirportSuggestions = [];
              } else {
                widget.selectedToAirport = airport;
                toAirportSuggestions = [];
              }
            });
          },
        );
      },
    );
  }

  // Build date time field with date restrictions
  Widget _buildDateTimeField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final now = DateTime.now();

        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: now,
          // ⛔ disables past dates
          lastDate: DateTime(now.year + 5),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (pickedTime != null) {
            final fullDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );

            final formatted =
                DateFormat('yyyy-MM-dd HH:mm').format(fullDateTime);
            controller.text = formatted;
          }
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Future<void> selectDateTime(
      BuildContext context, TextEditingController controller) async {
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
      TimeOfDay? pickedTime =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
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
