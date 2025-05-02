import 'package:flutter/material.dart';

import '../common/models/Task.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  TaskDetailScreen({Key? key, required this.task}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Details Heading
              Center(
                child: Text(
                  "Job Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.normal,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              SizedBox(height: 5),
              // Task Details
              Expanded(
                child: ListView(
                  children: [
                    detailCard("Broker ID", task.brokerId),
                    detailCard("Departure From", task.departureFrom),
                    detailCard("Arrive At", task.arriveAt),
                    detailCard("Start Date And Time", task.localStartDateTime),
                    detailCard("End Date And Time", task.localEndDateTime),
                    detailCard("Bid", task.bid),
                    detailCard("Description", task.description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card-style detail item
  Widget detailCard(String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            value ?? "N/A",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
