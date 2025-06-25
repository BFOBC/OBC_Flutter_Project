import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Milestoneinputform extends StatelessWidget {
  final int index;
  late String mileStoneNodeID;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController startController;
  final TextEditingController endController;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  Milestoneinputform({
    super.key,
    required this.index,
    required this.titleController,
    required this.descriptionController,
    required this.startController,
    required this.endController,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestone #$index',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 5),

                /// Title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 5),

                /// Description
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 5),

                /// Start Date
                TextField(
                  controller: startController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Time and Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDateTime(context, startController),
                ),
                const SizedBox(height: 5),

                /// End Date
                TextField(
                  controller: endController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'End Time and Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDateTime(context, endController),
                ),

                const SizedBox(height: 10),

                /// Save Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Milestone"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      textStyle: const TextStyle(fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15), // rounded corners
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Delete icon button
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Milestone',
              onPressed: () {
                _confirmDelete(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Milestone?'),
        content: const Text('Are you sure you want to delete this milestone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              onDelete(); // Trigger delete callback
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(
      BuildContext context, TextEditingController controller) async {
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
}
