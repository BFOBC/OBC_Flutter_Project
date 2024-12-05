import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../res/custom_colors.dart';
import '../common/utils/DateTimePicker.dart';
import 'data/Task.dart';

class Milestone {
  final String title;
  final String description;
  final String startTimeAndDate;
  final String endTimeAndDate;

  Milestone({
    required this.title,
    required this.description,
    required this.startTimeAndDate,
    required this.endTimeAndDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startTimeAndDate': startTimeAndDate,
      'endTimeAndDate': endTimeAndDate,
    };
  }

  static Milestone fromMap(Map<String, dynamic> map) {
    return Milestone(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTimeAndDate: map['startTimeAndDate'] ?? '',
      endTimeAndDate: map['endTimeAndDate'] ?? '',
    );
  }
}

class AddNewMilestone extends StatefulWidget {
  final Task? data;

  const AddNewMilestone({super.key, this.data});

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
      await milestonesCollection.add(milestone.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone saved successfully!')),
      );
      _clearFormFields();
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
    if (validateInputs()) {
      final newMilestone = Milestone(
        title: _summaryController.text,
        description: _descriptionController.text,
        startTimeAndDate: _startTimeAndDateController.text,
        endTimeAndDate: _endTimeAndDateController.text,
      );

      _saveMilestoneToFirestore(newMilestone);
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
