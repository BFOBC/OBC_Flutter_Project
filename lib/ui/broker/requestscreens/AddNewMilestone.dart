import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../res/custom_colors.dart';
import '../../common/utils/DateTimePicker.dart';
import '../../common/utils/RoleProvider.dart';

class AddNewMilestone extends StatefulWidget {
  final Task? data;
  final String courierKey;
  final String brokerKey;
  final Function(List<String> milestoneNodeID)?
      onMilestoneSaved; // Callback function

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
  String? _editingMilestoneNodeID;
  String? _originalStartDateTime;
  String? _originalEndDateTime;

  late List<String> listMilestoneNodeIDSLocal = [];
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeAndDateController = TextEditingController();
  final TextEditingController _endTimeAndDateController =
      TextEditingController();

  final CollectionReference milestonesCollection =
      FirebaseFirestore.instance.collection('milestones');

  bool _isViewButtonEnabled = true;

  Future<void> _saveMilestone(Milestone milestone) async {
    try {
      DocumentReference docRef = milestonesCollection.doc();
      milestone.milestoneNodeID = docRef.id;
      mileStoneNodeID = milestone.milestoneNodeID!;
      milestone.milestoneStatus = "pending";
      milestone.milestoneStartDateTime = convertToUTCFromCustomFormat(milestone.milestoneStartDateTime.toString());
      milestone.milestoneEndDateTime = convertToUTCFromCustomFormat(milestone.milestoneEndDateTime.toString());

      /// ✅ Save ID to provider without listening
      Provider.of<RoleProvider>(context, listen: false)
          .addMilestoneNodeID(mileStoneNodeID);

      /// ✅ Retrieve without listening
      if (widget.onMilestoneSaved != null) {
        List<String> ids = Provider.of<RoleProvider>(context, listen: false)
            .listMilestoneNodeIDS;
        widget.onMilestoneSaved!(ids);
      }

      await docRef.set(milestone.toMap());

      setState(() {
        _isViewButtonEnabled = true;
      });
      _clearFormFields();
/*      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone saved successfully!')),
      );*/
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving milestone: $e')),
      );
      print("Error saving milestone: $e");
    }
  }
  Future<void> _updateMilestone(String nodeID, Milestone milestone) async {
    try {
      final docRef = milestonesCollection.doc(nodeID);
      // Only convert to UTC if value has changed
      if (_startTimeAndDateController.text != _originalStartDateTime) {
        milestone.milestoneStartDateTime = convertToUTCFromCustomFormat(_startTimeAndDateController.text);
      }else{
        milestone.milestoneStartDateTime = convertToUTCFromCustomFormat2(_startTimeAndDateController.text);
      }
      if (_endTimeAndDateController.text != _originalEndDateTime) {
        milestone.milestoneEndDateTime = convertToUTCFromCustomFormat(_endTimeAndDateController.text);
      }else{
        milestone.milestoneEndDateTime = convertToUTCFromCustomFormat2(_endTimeAndDateController.text);
      }

      // ✅ Update milestone in Firestore
      await docRef.update(milestone.toMap());

      setState(() {
        _isViewButtonEnabled = true;
      });

      _clearFormFields();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone updated successfully!')),
      );
    } catch (e) {
      print("Error updating milestone: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating milestone: $e')),
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
    print("Validating inputs...");

    String startDateTime = "", endDateTime = "";

    if (_summaryController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _startTimeAndDateController.text.isEmpty ||
        _endTimeAndDateController.text.isEmpty) {
      print("Fields are empty. Showing Toast...");
      Future.delayed(Duration(milliseconds: 100), () {
        Fluttertoast.showToast(
          msg: "Please fill all fields correctly.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      });
      return false;
    }

    try {
      if (_startTimeAndDateController.text != _originalStartDateTime) {
        startDateTime = convertToUTCFromCustomFormat(_startTimeAndDateController.text);
      } else {
        startDateTime = convertToUTCFromCustomFormat2(_startTimeAndDateController.text);
      }

      if (_endTimeAndDateController.text != _originalEndDateTime) {
        endDateTime = convertToUTCFromCustomFormat(_endTimeAndDateController.text);
      } else {
        endDateTime = convertToUTCFromCustomFormat2(_endTimeAndDateController.text);
      }

      print("StartDateTime: $startDateTime");
      print("EndDateTime: $endDateTime");

      DateTime startDate = DateTime.parse(startDateTime);
      DateTime endDate = DateTime.parse(endDateTime);

      if (!startDate.isBefore(endDate)) {
        Fluttertoast.showToast(
          msg: "Start date must be before end date.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return false;
      }
    } catch (e) {
      print("Dates Format Error: $e");
      print("startDateTime: $startDateTime");
      print("endDateTime: $endDateTime");

      Fluttertoast.showToast(
        msg: "Invalid date format.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
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
      if (_editingMilestoneNodeID != null) {
        _updateMilestone(_editingMilestoneNodeID!, newMilestone);
        _editingMilestoneNodeID = null; // reset after update
      } else {
        _saveMilestone(newMilestone);
      }
    }
  }
  void _showMilestoneDialog() {
    List<String> ids =
        Provider.of<RoleProvider>(context, listen: false).listMilestoneNodeIDS;

    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No milestones available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Added Milestones',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: StreamBuilder<QuerySnapshot>(
            stream: milestonesCollection
                .where(FieldPath.documentId, whereIn: ids)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                Future.microtask(() {
                  Navigator.pop(dialogContext); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No milestones found')),
                  );
                });
                return const SizedBox.shrink();
              }

              return SizedBox(
                height: 300,
                width: 350,
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var milestone = snapshot.data!.docs[index];

                    // ✅ Use your method here
                    String startDate = convertUTCToLocal(milestone['milestoneStartDateTime']);
                    String endDate = convertUTCToLocal(milestone['milestoneEndDateTime']);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              milestone['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(milestone['description']),
                            Text(
                              'Start Date And Time: $startDate',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'End Date And Time: $endDate',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    _setMilestoneDataForEditing(milestone);
                                    Navigator.pop(dialogContext);
                                  },
                                  label: const Text("Edit",
                                      style: TextStyle(color: Colors.blue)),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showDeleteConfirmation(milestone.id),
                                  label: const Text("Delete",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
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
              onPressed: () => Navigator.pop(dialogContext),
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


  void _setMilestoneDataForEditing(QueryDocumentSnapshot milestone) {
    _summaryController.text = milestone['title'];
    _descriptionController.text = milestone['description'];
    _startTimeAndDateController.text =
        convertUTCToLocal(milestone['milestoneStartDateTime']);
    _endTimeAndDateController.text =
        convertUTCToLocal(milestone['milestoneEndDateTime']);

    _editingMilestoneNodeID = milestone.id; // 👈 yahan set karo

    _originalStartDateTime = _startTimeAndDateController.text;
    _originalEndDateTime = _endTimeAndDateController.text;
  }




  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Milestone"),
          content:
              const Text("Are you sure you want to delete this milestone?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog (Cancel)
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _clearFormFields();
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
          _isViewButtonEnabled = true;
        });
      }
      context.read<RoleProvider>().removeMilestoneNodeID(id);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  ),
                  child:
                      const Text('Save', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isViewButtonEnabled ? _showMilestoneDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  ),
                  child:
                      const Text('View', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
