import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/viewmodels/TaskViewModel.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Required for using TaskViewModel


class ViewMilestone extends StatelessWidget {
  String selectedTab;
  ViewMilestone({Key? key, required this.selectedTab}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final taskViewModel = Provider.of<TaskViewModel>(context);
    final tasks = taskViewModel.getTasksByStatus(selectedTab);
    
    

    return Scaffold(
      body: tasks.isEmpty
          ? const Center(
        child: Text("No milestones available"),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: task.status == "Done"
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
                          task.title.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Description: ${task.description}'),
                        const SizedBox(height: 4),
                        Text('Start: ${task.startDateTime}'),
                        const SizedBox(height: 4),
                        Text('End: ${task.endDateTime}'),
                        const SizedBox(height: 4),
                        Text('Status: ${task.status}'), // Display status
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      _showMilestoneDialog(context, task);
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
            ),
          );
        },
      ),
    );
  }

  void _showMilestoneDialog(BuildContext context, Task milestone) {
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
                    Text('Start Time: ${milestone.startDateTime}'),
                    const SizedBox(height: 10),
                    Text('End Time: ${milestone.endDateTime}'),
                    const SizedBox(height: 10),
                    Text('Status: ${milestone.status}'),
                    const SizedBox(height: 20),
                    Center(
                      child: selectedTab == "In Progress"
                          ? ElevatedButton(
                        onPressed: milestone.status == "Done"
                            ? null
                            : () {
                          final FirestoreService service = FirestoreService(context);
                          // Update job status
                          service.updateJobStatus(milestone.emptyLegRequestID.toString(), "Completed");
/*                          Provider.of<TaskViewModel>(context, listen: false)
                              .addTask(milestone.copyWith(status: "Done")); // Mark as done*/
                          Text('Status: Completed}');
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
                      )
                          : ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Close',
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
                  width: 30, // Reduced width
                  height: 30, // Reduced height
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero, // Remove default padding
                    icon: const Icon(Icons.close, color: Colors.white, size: 16), // Reduced icon size
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

}
