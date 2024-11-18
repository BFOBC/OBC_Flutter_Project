import 'package:flutter/material.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Map<String, String> taskDetails;

  const TaskDetailsScreen({super.key, required this.taskDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Broker ID: ${taskDetails['Broker ID']}'),
            const SizedBox(height: 8),
            Text('Flight Number: ${taskDetails['Flight Number']}'),
            const SizedBox(height: 8),
            Text('Departure From: ${taskDetails['Departure From']}'),
            const SizedBox(height: 8),
            Text('Arrive At: ${taskDetails['Arrive At']}'),
            const SizedBox(height: 8),
            // Add additional fields like Courier Capacity here
            Text('Courier Capacity: ${taskDetails['Courier Capacity'] ?? 'N/A'}'), // Example field
            const SizedBox(height: 8),
            // You can add more fields as needed
          ],
        ),
      ),
    );
  }
}
