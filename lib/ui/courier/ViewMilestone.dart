import 'package:flutter/material.dart';

class Milestone {
  String title;
  String description;
  String startTimeAndDate;
  String endTimeAndDate;
  String status; // Changed back to string

  Milestone({
    required this.title,
    required this.description,
    required this.startTimeAndDate,
    required this.endTimeAndDate,
    this.status = "In Progress", // Initial status
  });
}

class ViewMilestone extends StatefulWidget {
  final Milestone milestone;

  const ViewMilestone({super.key, required this.milestone});

  @override
  _ViewMilestoneState createState() => _ViewMilestoneState();
}

class _ViewMilestoneState extends State<ViewMilestone> {
  late Milestone _milestone;

  @override
  void initState() {
    super.initState();
    _milestone = widget.milestone;
  }

  void _showMilestoneDialog({required Milestone milestone}) {
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Title: ${milestone.title}'),
                    const SizedBox(height: 10),
                    Text('Description: ${milestone.description}'),
                    const SizedBox(height: 10),
                    Text('Start Time: ${milestone.startTimeAndDate}'),
                    const SizedBox(height: 10),
                    Text('End Time: ${milestone.endTimeAndDate}'),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: milestone.status == "Done"
                            ? null
                            : () {
                          setState(() {
                            // Mark the milestone as done
                            _milestone.status = "Done";
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Mark as Done',
                          style: TextStyle(color: Colors.white),
                        ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _milestone.status == "Done"
                            ? Colors.green
                            : Colors.grey,
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
                        _milestone.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Description: ${_milestone.description}'),
                      const SizedBox(height: 4),
                      Text('Start: ${_milestone.startTimeAndDate}'),
                      Text('End: ${_milestone.endTimeAndDate}'),
                      const SizedBox(height: 4),
                      Text('Status: ${_milestone.status}'), // Display status
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _showMilestoneDialog(milestone: _milestone);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(color: Colors.white), // Set text color to white
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
