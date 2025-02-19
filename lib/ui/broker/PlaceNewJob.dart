import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaceNewJob extends StatefulWidget {
  final Task? data;
  final Function(Task) onSave;

  const PlaceNewJob({super.key, this.data, required this.onSave});

  @override
  PlaceNewJobState createState() => PlaceNewJobState();
}

class PlaceNewJobState extends State<PlaceNewJob> {
  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  final TextEditingController _field3Controller = TextEditingController();
  final TextEditingController _field4Controller = TextEditingController();
  final TextEditingController _field5Controller = TextEditingController();
  final TextEditingController _fieldBidController = TextEditingController();
  bool _isViewEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _field1Controller.text = widget.data!.startDateTime!;
      _field2Controller.text = widget.data!.endDateTime!;
      _field3Controller.text = widget.data!.departureFrom!;
      _field4Controller.text = widget.data!.arriveAt!;
      _fieldBidController.text = widget.data!.bid!;
      _field5Controller.text = widget.data!.flightNumber!;
    }
  }

  bool validate() {
    return _field1Controller.text.isNotEmpty &&
        _field2Controller.text.isNotEmpty &&
        _field3Controller.text.isNotEmpty &&
        _field4Controller.text.isNotEmpty &&
        _fieldBidController.text.isNotEmpty &&
        _field5Controller.text.isNotEmpty;
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Submission Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            _buildTextField(_field1Controller, 'Start Time And Date', true),
            _buildTextField(_field2Controller, 'End Time And Date', true),
            _buildTextField(_field3Controller, 'Departure Location', false),
            _buildTextField(_field4Controller, 'Arrival Location', false),
            _buildTextField(_fieldBidController, 'Bid', false),
            _buildTextField(_field5Controller, 'Courier Capacity', false),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (validate()) {
                        Task newTask = Task(
                          startDateTime: _field1Controller.text,
                          endDateTime: _field2Controller.text,
                          departureFrom: _field3Controller.text,
                          arriveAt: _field4Controller.text,
                          bid: _fieldBidController.text,
                          flightNumber: _field5Controller.text,
                        );
                        widget.onSave(newTask);
                        setState(() => _isViewEnabled = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submission saved successfully!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields correctly.')),
                        );
                      }
                    },
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
                    onPressed: _isViewEnabled ? _showSubmissionDetails : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                    ),
                    child: const Text('View', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// View اور Delete ڈائیلاگ
  void _showSubmissionDetails() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submitted Details'),
          content: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Time: ${_field1Controller.text}'),
                  Text('End Time: ${_field2Controller.text}'),
                  Text('Departure: ${_field3Controller.text}'),
                  Text('Arrival: ${_field4Controller.text}'),
                  Text('Bid: ${_fieldBidController.text}'),
                  Text('Courier Capacity: ${_field5Controller.text}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _showDeleteConfirmation(), // کنفرمیشن ڈائیلاگ شو ہوگا
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Submission"),
          content: const Text("Are you sure you want to delete this submission?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // ڈائیلاگ بند ہوگا (No)
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(); // ڈائیلاگ بند کرنے کا درست طریقہ
                _deleteSubmission(); // ڈیلیٹ کی فنکشن کال
              },
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

// ڈیلیٹ کرنے کا فنکشن
  void _deleteSubmission() {
    setState(() {
      Navigator.pop(context); // Close confirmation dialog
      _isViewEnabled = false;
      _field1Controller.clear();
      _field2Controller.clear();
      _field3Controller.clear();
      _field4Controller.clear();
      _fieldBidController.clear();
      _field5Controller.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submission deleted successfully!')),
    );
  }



  Widget _buildTextField(TextEditingController controller, String label, bool isDateTime) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onTap: isDateTime ? () => _selectDateAndTime(controller) : null,
        readOnly: isDateTime,
      ),
    );
  }

  Future<void> _selectDateAndTime(TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day,
          selectedTime.hour, selectedTime.minute,
        );
        controller.text = '${selectedDateTime.toLocal()}'.split(' ')[0] +
            ' ${selectedDateTime.toLocal().toIso8601String().split('T')[1].split('.')[0]}';
      }
    }
  }

}