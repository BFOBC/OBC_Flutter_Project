import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/UpperCaseTextFormatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../data/notification/NotificationService.dart';
import 'milestoneinputform.dart'; // make sure this is the correct path

class SubmissionScreen extends StatefulWidget {
  final Task? data;
  final String brokerKey;
  final String courierKey;
  final Function(Task task) onSave;
  AirportModel? selectedFromAirport;
  AirportModel? selectedToAirport;

  SubmissionScreen({
    super.key,
    this.data,
    required this.brokerKey,
    required this.courierKey,
    required this.onSave,
  });

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final TextEditingController _submissionStartDateController =
      TextEditingController();
  final TextEditingController _submissionEndDateController =
      TextEditingController();
  final TextEditingController _submissionDepartureController =
      TextEditingController();
  final TextEditingController _submissionArrivalController =
      TextEditingController();
  final TextEditingController _submissionBidController =
      TextEditingController();
  final TextEditingController _submissionCourierController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();
  List<MilestoneFormData> milestoneForms = [];
  String emptyLegRequestID = "";
  late List<String> milestoneNodeID = [];

  List<AirportModel> fromAirportSuggestions =
      []; // Suggestions for "From Location"
  List<AirportModel> toAirportSuggestions = []; // Suggestions for "To Location"
  String? _selectedUnit;
  final List<String> _units = ['kg', 'g', 'lb', 'ton'];
  String? _selectedCurrency; // for dropdown selection

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _submissionStartDateController.text = widget.data!.startDateTime ?? '';
      _submissionEndDateController.text = widget.data!.endDateTime ?? '';
      _submissionDepartureController.text = widget.data!.departureFrom ?? '';
      _submissionArrivalController.text = widget.data!.arriveAt ?? '';
      _submissionCourierController.text = widget.data!.courierCapacity ?? '';
      _submissionBidController.text = widget.data!.bid ?? '';
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

  void _addMilestoneForm() {
    setState(() {
      milestoneForms.add(MilestoneFormData());
    });

    // Smooth scroll after delay
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeMilestoneForm(int index) {
    print("🚨 _removeMilestoneForm called with index: $index");

    try {
      print("📋 milestoneForms.length: ${milestoneForms.length}");
      print("📋 milestoneNodeID.length: ${milestoneNodeID.length}");

      if (index < 0 || index >= milestoneForms.length) {
        print("❌ Invalid index: $index in milestoneForms");
        return;
      }

      setState(() {
        final nodeID =
            (index < milestoneNodeID.length) ? milestoneNodeID[index] : null;

        milestoneForms.removeAt(index);

        if (index < milestoneNodeID.length) {
          milestoneNodeID.removeAt(index);
          print("🧾 nodeID to delete: $nodeID");
          deleteMilestoneByID(nodeID.toString()); // uncomment if needed
          print("✅ deleteMilestoneByID($nodeID) called");
        }

        print("✅ Removed from UI");
      });
    } catch (e, stack) {
      print("💥 Exception caught in _removeMilestoneForm:");
      print("🔴 Error: $e");
      print("📌 Stack trace:\n$stack");
    }
  }

  bool validate() {
    // Basic input field validation
    if (_submissionStartDateController.text.isEmpty ||
        _submissionEndDateController.text.isEmpty ||
        _submissionDepartureController.text.isEmpty ||
        _submissionArrivalController.text.isEmpty ){
      Fluttertoast.showToast(
        msg: "Please fill all fields correctly.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
      return false;
    }

    // ✅ Bid amount validation
    final bidText = _submissionBidController.text.trim();
    final bidValue = double.tryParse(bidText);

    if (bidValue == null || bidValue <= 0) {
      Fluttertoast.showToast(
        msg: "Please enter a valid bid amount.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
      return false;
    }
    // ✅ Currency validation
    if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select a currency.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
      return false;
    }

    // ✅ Capacity validation
    final capacityText = _submissionCourierController.text.trim();
    final capacity = double.tryParse(capacityText);

    if (capacity == null  || capacity <= 0) {
      Fluttertoast.showToast(
        msg: "Please enter a valid courier capacity.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
      return false;
    }

    if (capacity > 5000) {
      Fluttertoast.showToast(
        msg: "Courier capacity cannot exceed 5000.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
      return false;
    }




    // ✅ Date validation
    try {
      final start = DateTime.parse(_submissionStartDateController.text);
      final end = DateTime.parse(_submissionEndDateController.text);

      if (!start.isBefore(end)) {
        Fluttertoast.showToast(
          msg: "Start date must be before end date.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP,
        );
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Invalid date format.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }

    // ✅ Milestone presence check
    if (milestoneForms.isEmpty) {
      Fluttertoast.showToast(
        msg: "At least one milestone is required.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
      return false;
    }

    return true;
  }

  Widget _buildTextField2(
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

  Widget _buildTextField(
      TextEditingController controller, String label, bool readOnly) {
    final isNumberField = controller == _submissionCourierController ||
        controller == _submissionBidController;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: isNumberField ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: readOnly ? const Icon(Icons.calendar_today) : null,
        ),
        onTap: readOnly
            ? () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    final dt = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    controller.text = dt.toString();
                  }
                }
              }
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _submissionStartDateController.dispose();
    _submissionEndDateController.dispose();
    _submissionDepartureController.dispose();
    _submissionArrivalController.dispose();
    _submissionBidController.dispose();
    _submissionCourierController.dispose();

    for (var form in milestoneForms) {
      form.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Request New Job",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.lightGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor:
            Colors.white, // Ensures status bar icons/text are white
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextButton(
            onPressed: () {
              if (!validate()) return;

              bool allMilestonesValid = true;

              DateTime? submissionStart;
              DateTime? submissionEnd;

              try {
                submissionStart =
                    DateTime.parse(_submissionStartDateController.text);
                submissionEnd =
                    DateTime.parse(_submissionEndDateController.text);

                if (submissionStart.isAfter(submissionEnd)) {
                  Fluttertoast.showToast(
                    msg:
                        "Submission start date must be before or equal to end date.",
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    gravity: ToastGravity.TOP,
                  );
                  allMilestonesValid = false;
                }
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Invalid submission date format.",
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  gravity: ToastGravity.TOP,
                );
                allMilestonesValid = false;
              }

              if (allMilestonesValid) {
                for (int i = 0; i < milestoneForms.length; i++) {
                  final form = milestoneForms[i];

                  final title = form.titleController.text.trim();

                  // Check for empty fields
                  if (title.isEmpty ||
                      form.startController.text.isEmpty ||
                      form.endController.text.isEmpty) {
                    allMilestonesValid = false;
                    Fluttertoast.showToast(
                      msg: "Please complete all milestone #${i + 1} fields.",
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      gravity: ToastGravity.TOP,
                    );
                    break;
                  }

                  // Validate milestone dates
                  try {
                    final milestoneStart =
                        DateTime.parse(form.startController.text);
                    final milestoneEnd =
                        DateTime.parse(form.endController.text);

                    if (milestoneStart.isBefore(submissionStart!) ||
                        milestoneEnd.isAfter(submissionEnd!)) {
                      allMilestonesValid = false;
                      Fluttertoast.showToast(
                        msg:
                            "Milestone #${i + 1} (${title}) dates must be within submission date range.",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        gravity: ToastGravity.TOP,
                      );
                      break;
                    }
                  } catch (e) {
                    allMilestonesValid = false;
                    Fluttertoast.showToast(
                      msg: "Invalid date format in milestone #${i + 1}.",
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      gravity: ToastGravity.TOP,
                    );
                    break;
                  }
                }
              }

              String finalCapacity =
                  "${_submissionCourierController.text.trim()} ${_selectedUnit ?? ''}";
              String finalBid =
                  "${_submissionBidController.text.trim()} ${_selectedCurrency ?? ''}";

              if (allMilestonesValid) {
                Task task = Task(
                  startDateTime: _submissionStartDateController.text,
                  endDateTime: _submissionEndDateController.text,
                  departureFrom: _submissionDepartureController.text,
                  arriveAt: _submissionArrivalController.text,
                  bid: finalBid,
                  courierCapacity: finalCapacity, // 👈 updated field
                );

                widget.onSave(task);
                // ✅ Now store all milestoneForms to Firebase
                for (int i = 0; i < milestoneForms.length; i++) {
                  final form = milestoneForms[i];

                  final newMilestone = Milestone(
                      title: form.titleController.text,
                      description: form.descriptionController.text,
                      milestoneStartDateTime: form.startController.text,
                      milestoneEndDateTime: form.endController.text,
                      courierID: widget.courierKey,
                      milestoneNodeID: null,
                      brokerID: widget.brokerKey,
                      emptyLegRequestID: null);

                  _saveMilestoneToFirebase(newMilestone);
                }
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Palette.primaryColor),
                          SizedBox(height: 16),
                          Text('Sending request...', style: TextStyle(fontSize: 14, color: Palette.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
                try {
                  await sendEmptyLegRequest(context);
                } catch (e) {
                  if (context.mounted) Navigator.of(context).pop();
                  Fluttertoast.showToast(msg: 'Failed to send request. Please try again.');
                }
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Palette.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Request Job',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController, // <--- ADD THIS
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Submission Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // 🔹 Block B (Updated with From/To Location from Block A)
            const SizedBox(height: 10),

// Start & End Date/Time
            _buildTextField(
                _submissionStartDateController, 'Start Time And Date', true),
            _buildTextField(
                _submissionEndDateController, 'End Time And Date', true),

// From Location
            _buildStyledField(
              child: _buildTextField2(
                _submissionDepartureController,
                'From Location',
                onChanged: (value) {
                  if (value.length == 3) _fetchFromAirportData(value);
                },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  UpperCaseTextFormatter(),
                ],
              ),
            ),
            _buildSuggestionList(
                fromAirportSuggestions, _submissionDepartureController,
                isFrom: true),
// To Location
            _buildStyledField(
              child: _buildTextField2(
                _submissionArrivalController,
                'To Location',
                onChanged: (value) {
                  if (value.length == 3) _fetchToAirportData(value);
                },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  UpperCaseTextFormatter(),
                ],
              ),
            ),
            _buildSuggestionList(
                toAirportSuggestions, _submissionArrivalController,
                isFrom: false),
            //_buildTextField(_submissionCourierController, 'Bid', false),
            _buildBidField(),
            //_buildTextField(_submissionBidController, 'Courier Capacity', false),
            _buildCapacityField(),
            // 👈 yeh naya method use kia

            const SizedBox(height: 10),

            /// Add Milestone Button (centered + rectangular)
            Center(
              child: ElevatedButton.icon(
                onPressed: _addMilestoneForm,
                icon: const Icon(Icons.add),
                label: const Text("Add Milestone"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Rounded button
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            /// Milestone Forms
            AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Column(
                key: ValueKey(milestoneForms.length),
                children: milestoneForms.asMap().entries.map((entry) {
                  int i = entry.key;
                  final form = entry.value;

                  return KeyedSubtree(
                    key: ValueKey("milestone_$i"),
                    child: Milestoneinputform(
                      index: i + 1,
                      titleController: form.titleController,
                      descriptionController: form.descriptionController,
                      startController: form.startController,
                      endController: form.endController,
                      onSave: () {
                        print("🔍 onSave called for milestone index: $i");
                        if (form.titleController.text.isEmpty ||
                            form.startController.text.isEmpty ||
                            form.endController.text.isEmpty) {
                          Fluttertoast.showToast(
                            msg:
                                "Please complete all required fields for milestone #${i + 1}.",
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            gravity: ToastGravity.TOP,
                          );
                          return;
                        }
                        Fluttertoast.showToast(
                          msg: "Milestone #${i + 1} saved.",
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          gravity: ToastGravity.TOP,
                        );
                      },
                      onDelete: () {
                        print("🗑️ Delete tapped on index: $i");
                        _removeMilestoneForm(i);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _saveMilestoneToFirebase(Milestone milestone) async {
    try {
      final CollectionReference milestonesCollection =
          FirebaseFirestore.instance.collection('milestones');

      DocumentReference docRef = milestonesCollection.doc();
      milestone.milestoneNodeID = docRef.id;
      milestone.milestoneStatus = "pending";
      milestoneNodeID.add(docRef.id);
      milestone.milestoneStartDateTime = convertToUTCFromStandardFormat(
          milestone.milestoneStartDateTime.toString());
      milestone.milestoneEndDateTime = convertToUTCFromStandardFormat(
          milestone.milestoneEndDateTime.toString());

      await docRef.set(milestone.toMap()); // Make sure Milestone has toMap()

/*      Fluttertoast.showToast(
        msg: "Milestone '${milestone.title}' saved.",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );*/
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error saving milestone: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> deleteMilestoneByID(String milestoneID) async {
    try {
      // Reference to the document in the milestones collection
      DocumentReference docRef =
          FirebaseFirestore.instance.collection('milestones').doc(milestoneID);

      // Delete the document
      await docRef.delete();

      print('Milestone with ID $milestoneID deleted successfully.');
    } catch (e) {
      print('Error deleting milestone: $e');
    }
  }
// --- Bid Field Widget ---
  Widget _buildBidField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Bid Amount Field ---
          Expanded(
            flex: 2,
            child: TextField(
              controller: _submissionBidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bid Amount',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // --- Currency Dropdown ---
          Expanded(
            flex: 1,
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                isExpanded: true, // 👈 important fix
                hint: const Text('Currency'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'USD',
                    child: Text('USD (\$)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'EUR',
                    child: Text('EUR (€)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // --- Capacity Field ---
          Expanded(
            flex: 2,
            child: TextField(
              controller: _submissionCourierController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Courier Capacity',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // --- Unit Dropdown ---
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _selectedUnit,
              hint: const Text('Unit'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _units.map((String unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendEmptyLegRequest(BuildContext context) async {
    // Clear milestone list from provider
    Provider.of<RoleProvider>(context, listen: false).clearMilestoneNodeIDS();
    Provider.of<RoleProvider>(context, listen: false).clearTask();
    FirestoreService firestoreService = FirestoreService(context);

    // Create a new EmptyLegRequest with nodeID initially null
    String finalCapacity =
        "${_submissionCourierController.text.trim()} ${_selectedUnit ?? ''}";
    String finalBid =
        "${_submissionBidController.text.trim()} ${_selectedCurrency ?? ''}";

    EmptyLegRequest newRequest = EmptyLegRequest(
      brokerID: widget.brokerKey,
      courierID: widget.courierKey,
      emptyLegRequestID: emptyLegRequestID,
      requestDateTime: DateTime.now().toIso8601String(),
      status: 'pending',
      milestoneNodeIDs: milestoneNodeID,
      startTimeDate: _submissionStartDateController.text,
      endTimeDate: _submissionEndDateController.text,
      departureLocation: _submissionDepartureController.text,
      arrivalLocation: _submissionArrivalController.text,
      bid: finalBid,
      isCourierRated: 'false',
      isBrokerRated: 'false',
      courierCapacity: finalCapacity,
    );
    newRequest.startTimeDate =
        convertToUTCFromStandardFormat(newRequest.startTimeDate.toString());
    newRequest.endTimeDate =
        convertToUTCFromStandardFormat(newRequest.endTimeDate.toString());

    print(newRequest.startTimeDate.toString());

    // Get courier and broker data for notification
    final User currentUser = FirebaseAuth.instance.currentUser!;
    final courierData =
    await NotificationService.getCourierNameAndTokenById(widget.courierKey);
    final brokerData =
    await NotificationService.getBrokerNameAndTokenById(currentUser.uid);

    print("User FCM Info: $courierData");

    // Save the request and send notification concurrently
    String? requestId;
    await Future.wait([
      // Save the request and capture the requestId
      firestoreService.saveEmptyLegRequest(newRequest, milestoneNodeID).then((id) {
        requestId = id; // Store the requestId
      }),
      // Send notification
      if (courierData != null)
        NotificationService.sendNotification(
          title: "New Request",
          toToken: courierData['token']!,
          type: "broker_request",
          screen: "DrawerScreen",
          extraData: {"senderName": brokerData?['name']},
        ),
    ]);

    // Step 3: Hide loading dialog
    Navigator.of(context).pop();

    // Check if request was saved successfully
    if (requestId != null) {
      print("EmptyLegRequest ID: $requestId");
    } else {
      print("Failed to save request.");
    }

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.primaryColor.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_circle_rounded, color: Palette.primaryColor, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Request Sent!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Palette.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your job request has been sent successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Palette.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToDrawerPage();
                    },
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Navigate back after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _navigateToDrawerPage();
      }
    });
  }

  void _navigateToDrawerPage() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushNamed('/DrawerScreen');
  }
}

Widget _buildStyledField({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(
      horizontal: 1, // 👈 pehle 12 tha, ab kam kar diya
      vertical: 4,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

/// Helper class to hold form controllers
class MilestoneFormData {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    startController.dispose();
    endController.dispose();
  }
}
