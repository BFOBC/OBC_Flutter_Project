import 'package:flutter/material.dart';
import '../../res/custom_colors.dart';
import '../common/utils/CustomDialog.dart';
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
}

class AddNewMilestone extends StatefulWidget {
  final Task? data; // Replace YourDataType with the actual type of your data object
  const AddNewMilestone({Key? key, this.data}) : super(key: key);

  @override
  _AddNewMilestoneScreenState createState() => _AddNewMilestoneScreenState();
}

class _AddNewMilestoneScreenState extends State<AddNewMilestone> {
  final List<Milestone> _milestones = [];

  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeAndDateController =
  TextEditingController();
  final TextEditingController _endTimeAndDateController =
  TextEditingController();

  Milestone? _editingMilestone;
  int? _editingIndex;

  // Function to validate and submit a milestone
  void _validateAndSubmit({bool isUpdating = false}) {
    bool isValid = true;
    String errorMessage = '';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } else {
      if (isUpdating && _editingIndex != null) {
        setState(() {
          _milestones[_editingIndex!] = Milestone(
            title: _summaryController.text,
            description: _descriptionController.text,
            startTimeAndDate: _startTimeAndDateController.text,
            endTimeAndDate: _endTimeAndDateController.text,
          );
        });
        _editingMilestone = null;
        _editingIndex = null;
      } else {
        setState(() {
          _milestones.add(
            Milestone(
              title: _summaryController.text,
              description: _descriptionController.text,
              startTimeAndDate: _startTimeAndDateController.text,
              endTimeAndDate: _endTimeAndDateController.text,
            ),
          );
        });
      }
      _clearFormFields();
      Navigator.of(context).pop();
    }
  }

  void _clearFormFields() {
    _summaryController.clear();
    _descriptionController.clear();
    _startTimeAndDateController.clear();
    _endTimeAndDateController.clear();
  }

  void _showMilestoneDialog({Milestone? milestone, int? index}) {
    if (milestone != null) {
      _editingMilestone = milestone;
      _editingIndex = index;
      _summaryController.text = milestone.title;
      _descriptionController.text = milestone.description;
      _startTimeAndDateController.text = milestone.startTimeAndDate;
      _endTimeAndDateController.text = milestone.endTimeAndDate;
    } else {
      _clearFormFields();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Milestone Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _summaryController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _startTimeAndDateController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time and Date',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () {
                        _selectDateAndTime(_startTimeAndDateController);
                      },
                      readOnly: true,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _endTimeAndDateController,
                      decoration: const InputDecoration(
                        labelText: 'End Time and Date',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () {
                        _selectDateAndTime(_endTimeAndDateController);
                      },
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    if (milestone != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _validateAndSubmit(isUpdating: true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Update', style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _milestones.removeAt(index!);
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ] else
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            _validateAndSubmit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Add Milestone', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Milestone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Handle back press
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _milestones.isEmpty
                    ? const Center(child: Text('No milestones added.'))
                    : ListView.builder(
                  itemCount: _milestones.length,
                  itemBuilder: (context, index) {
                    final milestone = _milestones[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  milestone.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Description: ${milestone.description}'),
                                const SizedBox(height: 4),
                                Text('Start: ${milestone.startTimeAndDate}'),
                                Text('End: ${milestone.endTimeAndDate}'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              _showMilestoneDialog(milestone: milestone, index: index);
                            },
                            child: const Icon(Icons.edit),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showMilestoneDialog();
                  },
                  child: const Text('Add Milestone'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateAndTime(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        controller.text =
        '${pickedDate.toLocal()} ${pickedTime.hour}:${pickedTime.minute}';
      }
    }
  }
}
