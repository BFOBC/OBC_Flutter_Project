import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'milestoneinputform.dart'; // make sure this is the correct path

class SubmissionScreen extends StatefulWidget {
  final Task? data;
  final String brokerKey;
  final String courierKey;
  final Function(Task task) onSave;

  const SubmissionScreen({
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
  final TextEditingController _submissionStartDateController = TextEditingController();
  final TextEditingController _submissionEndDateController = TextEditingController();
  final TextEditingController _submissionDepartureController = TextEditingController();
  final TextEditingController _submissionArrivalController = TextEditingController();
  final TextEditingController _submissionBidController = TextEditingController();
  final TextEditingController _submissionCourierController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  List<MilestoneFormData> milestoneForms = [];
  String emptyLegRequestID = "";
  late List<String> milestoneNodeID = [];

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _submissionStartDateController.text = widget.data!.startDateTime ?? '';
      _submissionEndDateController.text = widget.data!.endDateTime ?? '';
      _submissionDepartureController.text = widget.data!.departureFrom ?? '';
      _submissionArrivalController.text = widget.data!.arriveAt ?? '';
      _submissionCourierController.text = widget.data!.bid ?? '';
      _submissionBidController.text = widget.data!.bid ?? '';
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
        final nodeID = (index < milestoneNodeID.length)
            ? milestoneNodeID[index]
            : null;

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
        _submissionArrivalController.text.isEmpty ||
        _submissionCourierController.text.isEmpty ||
        _submissionBidController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill all fields correctly.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP, // 👈 This moves it to the top
      );
      return false;
    }

    // Date validation
    try {
      final start = DateTime.parse(_submissionStartDateController.text);
      final end = DateTime.parse(_submissionEndDateController.text);

      if (!start.isBefore(end)) {
        Fluttertoast.showToast(
          msg: "Start date must be before end date.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP, // 👈 This moves it to the top
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

    // Milestone presence check
    if (milestoneForms.isEmpty) {
      Fluttertoast.showToast(
        msg: "At least one milestone is required.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP, // 👈 This moves it to the top
      );
      return false;
    }

    return true;
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
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
        foregroundColor: Colors.white, // Ensures status bar icons/text are white
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
                submissionStart = DateTime.parse(_submissionStartDateController.text);
                submissionEnd = DateTime.parse(_submissionEndDateController.text);

                if (submissionStart.isAfter(submissionEnd)) {
                  Fluttertoast.showToast(
                    msg: "Submission start date must be before or equal to end date.",
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
                    final milestoneStart = DateTime.parse(form.startController.text);
                    final milestoneEnd = DateTime.parse(form.endController.text);

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


              if (allMilestonesValid) {
                Task task = Task(
                  startDateTime: _submissionStartDateController.text,
                  endDateTime: _submissionEndDateController.text,
                  departureFrom: _submissionDepartureController.text,
                  arriveAt: _submissionArrivalController.text,
                  bid: _submissionCourierController.text,
                  courierCapacity: _submissionBidController.text,
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
                sendEmptyLegRequest(context);
               // Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // makes it rounded
              ),
            ),
            child: const Text(
              'Request Job',
              style: TextStyle(color: Colors.white, fontSize: 14),
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

            const SizedBox(height: 10),
            _buildTextField(_submissionStartDateController, 'Start Time And Date', true),
            _buildTextField(_submissionEndDateController, 'End Time And Date', true),
            _buildTextField(_submissionDepartureController, 'Departure Location', false),
            _buildTextField(_submissionArrivalController, 'Arrival Location', false),
            _buildTextField(_submissionCourierController, 'Bid', false),
            _buildTextField(_submissionBidController, 'Courier Capacity', false),
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
                            msg: "Please complete all required fields for milestone #${i + 1}.",
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

  Future<void> _saveMilestoneToFirebase(Milestone milestone) async {
    try {
      final CollectionReference milestonesCollection =
          FirebaseFirestore.instance.collection('milestones');

      DocumentReference docRef = milestonesCollection.doc();
      milestone.milestoneNodeID = docRef.id;
      milestone.milestoneStatus = "pending";
      milestoneNodeID.add( docRef.id);
      milestone.milestoneStartDateTime = convertToUTCFromStandardFormat(
          milestone.milestoneStartDateTime.toString());
      milestone.milestoneEndDateTime = convertToUTCFromStandardFormat(
          milestone.milestoneEndDateTime.toString());

      await docRef.set(milestone.toMap()); // Make sure Milestone has toMap()

      Fluttertoast.showToast(
        msg: "Milestone '${milestone.title}' saved.",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
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
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('milestones')
          .doc(milestoneID);

      // Delete the document
      await docRef.delete();

      print('Milestone with ID $milestoneID deleted successfully.');
    } catch (e) {
      print('Error deleting milestone: $e');
    }
  }

  Future<void> sendEmptyLegRequest(BuildContext context) async {
    // Clear milestone list from provider
    Provider.of<RoleProvider>(context, listen: false).clearMilestoneNodeIDS();
    Provider.of<RoleProvider>(context, listen: false).clearTask();
    FirestoreService firestoreService = FirestoreService(context);
    // Create a new EmptyLegRequest with nodeID initially null

    EmptyLegRequest newRequest = EmptyLegRequest(
        brokerID: widget.brokerKey,
        courierID: widget.courierKey,
        emptyLegRequestID: emptyLegRequestID,
        // Will be updated when saving
        requestDateTime: DateTime.now().toIso8601String(),
        status: 'pending',// Now using a list
        milestoneNodeIDs: milestoneNodeID,
        startTimeDate: _submissionStartDateController.text,
        endTimeDate:_submissionEndDateController.text,
        departureLocation: _submissionDepartureController.text,
        arrivalLocation: _submissionArrivalController.text,
        bid: _submissionBidController.text,
        isCourierRated: 'false',
        isBrokerRated: 'false',
        courierCapacity:_submissionCourierController.text

    );
    newRequest.startTimeDate=convertToUTCFromStandardFormat(newRequest.startTimeDate.toString());
    newRequest.endTimeDate=convertToUTCFromStandardFormat(newRequest.endTimeDate.toString());
    // Save the request to Firestore
    print(newRequest.startTimeDate.toString());


    String? requestId = await firestoreService.saveEmptyLegRequest(newRequest, milestoneNodeID);

    if (requestId != null) {
      print("EmptyLegRequest ID: $requestId");
    } else {
      print("Failed to save request.");
    }



    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 10),
              const Text('Job request sent successfully'),
            ],
          ),
          actions: [
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _navigateToDrawerPage(); // Navigate to the Drawer page
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

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
