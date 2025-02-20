import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../res/custom_colors.dart';
import '../common/utils/DateTimePicker.dart';

class AddNewMilestone extends StatefulWidget {
  final Task? data;
  final String courierKey;
  final String brokerKey;
  final Function(List<String> milestoneNodeID)? onMilestoneSaved; // Callback function

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
  late List<String> listMilestoneNodeIDS = [];
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeAndDateController = TextEditingController();
  final TextEditingController _endTimeAndDateController = TextEditingController();

  final CollectionReference milestonesCollection =
  FirebaseFirestore.instance.collection('milestones');

  bool _isViewButtonEnabled = false;

  Future<void> _saveMilestone(Milestone milestone) async {
    try {
      DocumentReference docRef = milestonesCollection.doc();
      milestone.milestoneNodeID = docRef.id;
      mileStoneNodeID = milestone.milestoneNodeID!;
      milestone.milestoneStatus = "pending";
      listMilestoneNodeIDS.add(mileStoneNodeID);

      if (widget.onMilestoneSaved != null) {
        widget.onMilestoneSaved!(listMilestoneNodeIDS);
      }

      await docRef.set(milestone.toMap());

      setState(() {
        _isViewButtonEnabled = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving milestone: $e')),
      );
      print("Error saving milestone: $e");
    }
  }

  void _clearFormFields() {
    _summaryController.clear();
    _descriptionController.clear();
    _startTimeAndDateController.clear();
    _endTimeAndDateController.clear();
  }

  bool validateInputs() {
    if (_summaryController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _startTimeAndDateController.text.isEmpty ||
        _endTimeAndDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly.')),
      );
      return false;
    }
    return true;
  }

  void _submitForm() {
    if (validateInputs()) {
      final newMilestone = Milestone(
        title: _summaryController.text,
        description: _descriptionController.text,
        milestoneStartDateTime: _startTimeAndDateController.text,
        milestoneEndDateTime: _endTimeAndDateController.text,
        courierID: widget.courierKey,
        milestoneNodeID: null,
        brokerID: widget.brokerKey,
      );

      _saveMilestone(newMilestone);
    }
  }
  void _showMilestoneDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Saved Milestones',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: listMilestoneNodeIDS.isEmpty
              ? const SizedBox(height: 100, child: Center(child: Text("No milestones found."))) // Handle empty list
              : StreamBuilder<QuerySnapshot>(
            stream: milestonesCollection
                .where(FieldPath.documentId, whereIn: listMilestoneNodeIDS)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _isViewButtonEnabled = false;
                  });
                  Navigator.pop(context); // Close dialog if no data
                });
                return const SizedBox();
              }

              return SizedBox(
                height: 300,
                width: 350,
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var milestone = snapshot.data!.docs[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        title: Text(
                          milestone['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(milestone['description']),
                            const SizedBox(height: 5),
                            Text(
                              'Start Date And Time: ${milestone['milestoneStartDateTime']}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'End Date And Time: ${milestone['milestoneEndDateTime']}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(milestone.id),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }


  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Milestone"),
          content: const Text("Are you sure you want to delete this milestone?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog (Cancel)
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close confirmation dialog
                _deleteMilestone(id); // Proceed with deletion
              },
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  Future<void> _deleteMilestone(String id) async {
    try {
      await milestonesCollection.doc(id).delete();

      var snapshot = await milestonesCollection.get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _isViewButtonEnabled = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting milestone: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Milestone Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isViewButtonEnabled ? _showMilestoneDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  ),
                  child: const Text('View', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
