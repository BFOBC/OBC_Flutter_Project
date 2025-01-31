import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../res/custom_colors.dart';
import '../common/utils/DateTimePicker.dart';


class AddNewMilestone extends StatefulWidget {
  final Task? data;
  final String emptyLegRequestID;


   AddNewMilestone({required this.emptyLegRequestID, this.data});

  @override
  AddNewMilestoneScreenState createState() => AddNewMilestoneScreenState();
}

class AddNewMilestoneScreenState extends State<AddNewMilestone> {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeAndDateController =
      TextEditingController();
  final TextEditingController _endTimeAndDateController = TextEditingController();


  final CollectionReference milestonesCollection =
      FirebaseFirestore.instance.collection('milestones');

  Future<void> _saveMilestoneToFirestore(Milestone milestone) async {
    try {
      // Step 1: Add the milestone to Firestore and get the document reference
      DocumentReference docRef = await milestonesCollection.add(milestone.toMap());

      // Step 2: Update the milestoneNodeID in the object
      milestone.milestoneNodeID = docRef.id;

      // Step 3: Update Firestore with the correct milestoneNodeID
      await docRef.update({'milestoneNodeID': docRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone saved successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving milestone: $e')),
      );
    }
  }

  void _clearFormFields() {
    _summaryController.clear();
    _descriptionController.clear();
    _startTimeAndDateController.clear();
    _endTimeAndDateController.clear();
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

      _saveMilestoneToFirestore(newMilestone).then((_) {
        // Navigate back to the previous screen after saving
        Navigator.pop(context);
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
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Example: Allow letters
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
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save Milestone',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
