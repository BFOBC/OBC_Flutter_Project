import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/broker/mission/BrokerMissions.dart';
import 'package:broker_flutter_pp/ui/common/models/FlightData.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/utils/CustomDialog.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/models/Task.dart';

class AddNewMilestoneEmptyLeg extends StatefulWidget {
  final Task? data;
  String emptyLegRequestID="";
  String courierID;
  FlightData flightData;
  AddNewMilestoneEmptyLeg({required this.courierID,required this.flightData, this.data});

  @override
  AddNewMilestoneEmptyLegScreenState createState() => AddNewMilestoneEmptyLegScreenState();
}

class AddNewMilestoneEmptyLegScreenState extends State<AddNewMilestoneEmptyLeg> {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeAndDateController =
  TextEditingController();
  final TextEditingController _endTimeAndDateController = TextEditingController();

  List<Map<String, dynamic>> milestones = [];
  List<String> milestoneIds = [];

  bool isEditing = false;
  String? editingMilestoneId;

  final CollectionReference milestonesCollection =
  FirebaseFirestore.instance.collection('milestones');

  Future<void> _saveMilestoneToFireStore(Milestone milestone) async {
    try {
      // Step 1: Add the milestone to Firestore and get the document reference
      DocumentReference docRef = await milestonesCollection.add(milestone.toMap());

      // Step 2: Update the milestoneNodeID in the object
      milestone.milestoneNodeID = docRef.id;
      milestoneIds.add(docRef.id); // ✅ ID list mein add karo

      // Step 3: Update Firestore with the correct milestoneNodeID
      await docRef.update({'milestoneNodeID': docRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Milestone saved successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      clearFields();
      _fetchMilestones(widget.emptyLegRequestID);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving milestone: $e')),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    _fetchMilestones(widget.emptyLegRequestID);
  }
  Future<void> _fetchMilestones(String emptyLegRequestID) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('milestones')
          .where('emptyLegRequestID', isEqualTo: emptyLegRequestID)
          .get();

      setState(() {
        milestones = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      print('Error fetching milestones: $e');
    }
  }

  Future<void> _deleteMilestone(String id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete Milestone',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this milestone?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog

                await FirebaseFirestore.instance.collection('milestones').doc(id).delete();

                setState(() {
                  milestoneIds.remove(id); // ✅ Removes the ID from the list
                });

                _fetchMilestones(widget.emptyLegRequestID); // Refresh the UI or list

                Future.microtask(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Milestone Deleted!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                });
              },
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _editMilestone(String id, Map<String, dynamic> data) {
    setState(() {
      isEditing = true;
      editingMilestoneId = id;

      _summaryController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _startTimeAndDateController.text = data['milestoneStartDateTime'] ?? '';
      _endTimeAndDateController.text = data['milestoneEndDateTime'] ?? '';
    });
  }
  void clearFields(){
    _summaryController.clear();
    _descriptionController.clear();
    _startTimeAndDateController.clear();
    _endTimeAndDateController.clear();
  }
  Future<void> _updateMilestone() async {
    if (editingMilestoneId == null) return;

    await FirebaseFirestore.instance.collection('milestones').doc(editingMilestoneId).update({
      'title': _summaryController.text,
      'description': _descriptionController.text,
      'milestoneStartDateTime': _startTimeAndDateController.text,
      'milestoneEndDateTime': _endTimeAndDateController.text,
    });

    // Reset form and state
    setState(() {
      isEditing = false;
      editingMilestoneId = null;
    });

    clearFields();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Milestone updated successfully!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );

    _fetchMilestones(widget.emptyLegRequestID);
  }


  bool validateInputs() {
    String errorMessage = '';
    bool isValid = true;

    if (_summaryController.text.isEmpty) {
      isValid = false;
      errorMessage += 'Summary is required.\n';
    }
    if (_descriptionController.text.isEmpty) {
      isValid = false;
      errorMessage += 'Description is required.\n';
    }
    if (_startTimeAndDateController.text.isEmpty) {
      isValid = false;
      errorMessage += 'Start Time and Date is required.\n';
    }
    if (_endTimeAndDateController.text.isEmpty) {
      isValid = false;
      errorMessage += 'End Time and Date is required.\n';
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }

    return isValid;
  }

  void _submitForm() {
    late User currentUser = FirebaseAuth.instance.currentUser!;

    if (validateInputs()) {
      final newMilestone = Milestone(
          title: _summaryController.text,
          description: _descriptionController.text,
          milestoneStartDateTime: _startTimeAndDateController.text,
          milestoneEndDateTime: _endTimeAndDateController.text,
          emptyLegRequestID: widget.emptyLegRequestID.toString(),
          brokerID: widget.data?.brokerId.toString(),
          courierID: currentUser.uid.toString(),
          milestoneStatus: "pending"
      );

      _saveMilestoneToFireStore(newMilestone).then((_) {
      }).catchError((error) {
        // Handle any errors that occur during saving
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save milestone: $error')),
        );
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Milestone'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Milestone Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _startTimeAndDateController,
              decoration: const InputDecoration(
                labelText: 'Start Time and Date',
                border: OutlineInputBorder(),
              ),
              onTap: () {
                selectDateTime(context, _startTimeAndDateController);
              },
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endTimeAndDateController,
              decoration: const InputDecoration(
                labelText: 'End Time and Date',
                border: OutlineInputBorder(),
              ),
              onTap: () {
                selectDateTime(context, _endTimeAndDateController);
              },
              readOnly: true,
            ),
            const SizedBox(height: 10),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save / Update Button
                  SizedBox(
                    width: 250,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isEditing) {
                          _updateMilestone();
                        } else {
                          _submitForm();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Milestone' : 'Save Milestone',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Only show this button if milestoneIds is not empty
                  if (milestoneIds.isNotEmpty)
                    SizedBox(
                      width: 250,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flight_takeoff, color: Colors.white),
                        label: const Text(
                          'Book the Empty Leg',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          await _sendBookRequestAndUpdateMilestones();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    '🗂️ Milestones Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: milestones.length,
                  itemBuilder: (context, index) {
                    final milestone = milestones[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.flag, color: Colors.blueGrey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    milestone['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      onPressed: () => _editMilestone(milestone['milestoneNodeID'], milestone),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteMilestone(milestone['milestoneNodeID']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (milestone['description'] != null && milestone['description'].toString().isNotEmpty)
                              Text(
                                "📋 Description: ${milestone['description']}",
                                style: const TextStyle(fontSize: 15),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              "📅 Start: ${milestone['milestoneStartDateTime'] ?? 'N/A'}",
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "📅 End: ${milestone['milestoneEndDateTime'] ?? 'N/A'}",
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }


void selectDateTime(BuildContext context, TextEditingController controller) async {
  final date = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (date != null) {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      controller.text = dateTime.toString();
    }
  }
}

  Future<void> _sendBookRequestAndUpdateMilestones() async {
    try {
      String brokerID = getCurrentUserId();
      String nodeID = FirebaseFirestore.instance.collection('emptyLegRequests').doc().id;
      String currentDateTime = DateTime.now().toString();
      String UTCTime = convertToUTCFromStandardFormat(currentDateTime);

      // ✅ Save emptyLegRequest
      await FirebaseFirestore.instance.collection('emptyLegRequests').doc(nodeID).set({
        'emptyLegRequestID': nodeID,
        'brokerID': brokerID,
        'status': "pending",
        'requestDateTime': UTCTime,
        'courierID': widget.courierID,
        'arrivalLocation': widget.flightData.fromLocation,
        'departureLocation': widget.flightData.toLocation,
        'endTimeDate': widget.flightData.toDateTime.toString(),
        'startTimeDate': widget.flightData.fromDateTime,
        'emptyLegTBLNodeID': widget.flightData.emptyLegTBLNodeID.toString()
      });

      // ✅ Update all milestones with this emptyLegRequestID
      for (String milestoneID in milestoneIds) {
        await FirebaseFirestore.instance
            .collection('milestones')
            .doc(milestoneID)
            .update({'emptyLegRequestID': nodeID});
      }

      // ✅ Update the emptyLeg document status to "pending"
      await FirebaseFirestore.instance
          .collection('emptyLegs')
          .doc(widget.flightData.emptyLegTBLNodeID)
          .update({'status': 'pending'});

      showCustomDialog2(context, "Request Successfully");
    } catch (e) {
      CustomDialog.showCustomDialog2(context, "Error: ${e.toString()}");
    }
  }


  String getCurrentUserId() {
    // Replace this with your actual logic to retrieve the user ID
    return FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  }

  Future<void> showCustomDialog2(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      // 👈 true = dialog closes on back press or tap outside
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(dialogContext).pop(); // Close the dialog on back press
            return false; // prevent pushing anything else
          },
          child: AlertDialog(
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
                Text(message),
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
                      Navigator.of(dialogContext).pop(); // Close dialog
                      Navigator.pushReplacement(
                        // ✅ replace so it doesn't go back
                        context,
                        MaterialPageRoute(
                          builder: (context) => BrokerMissions(),
                        ),
                      );
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}