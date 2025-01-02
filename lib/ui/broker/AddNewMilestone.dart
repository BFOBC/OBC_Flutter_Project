import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../res/custom_colors.dart';
import '../common/utils/DateTimePicker.dart';

class AddNewMilestone extends StatefulWidget {
  final Task? data;

  String courierKey;
  String brokerKey;
  final Function(String milestoneNodeID)? onMilestoneSaved; // Callback function

  AddNewMilestone({
    super.key,
    this.data,
    required this.courierKey,
    required this.brokerKey,
    this.onMilestoneSaved,
  });

  @override
  AddNewMilestoneScreenState createState() => AddNewMilestoneScreenState();
}

class AddNewMilestoneScreenState extends State<AddNewMilestone> {
  late String mileStoneNodeID;
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeAndDateController =
      TextEditingController();
  final TextEditingController _endTimeAndDateController =
      TextEditingController();

  final CollectionReference milestonesCollection =
      FirebaseFirestore.instance.collection('milestones');

  Future<void> _saveMilestone(Milestone milestone) async {
    try {
      // Create a reference to a new document with an auto-generated ID
      DocumentReference docRef = milestonesCollection.doc();

      // Update the nodeID in the milestone object
      milestone.nodeID = docRef.id;
      mileStoneNodeID= milestone.nodeID!;
      // Invoke the callback
      if (widget.onMilestoneSaved != null) {
        widget.onMilestoneSaved!(milestone.nodeID!);
      }
      // Save the milestone model with the updated nodeID
      await docRef.set(milestone.toMap());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone saved successfully!')),
      );

      //_clearFormFields(); // Uncomment if you want to clear the form fields after saving
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving milestone: $e')),
      );

      // Log the error
      print("Error saving milestone:");
      print(e.toString());
    }
  }
  String getmilestoneID(){
    return mileStoneNodeID;
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

 /*   if (!isValid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }*/

    return isValid;
  }

  void _submitForm() {
    if (validateInputs()) {
      final newMilestone = Milestone(
          title: _summaryController.text,
          description: _descriptionController.text,
          startTimeAndDate: _startTimeAndDateController.text,
          endTimeAndDate: _endTimeAndDateController.text,
          courierID: widget.courierKey,
          nodeID: null,
          brokerID: widget.brokerKey);

      _saveMilestone(newMilestone);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: null, // Remove title
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Only horizontal padding, remove top and bottom
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Milestone Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
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
                  backgroundColor: Palette.primaryColor, // Green background (same as previous button)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 5), // Larger button
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white), // White text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
