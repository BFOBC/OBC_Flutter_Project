import 'package:flutter/material.dart';

import '../common/utils/CustomDialog.dart';
import 'Milestone.dart';

class JobDetails extends StatelessWidget {
  const JobDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures the buttons stay at the bottom
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildInfoCard('Start Date Time', '2024-09-30 08:00 AM'),
                const SizedBox(height: 10),
                _buildInfoCard('End Date Time', '2024-09-30 06:00 PM'),
                const SizedBox(height: 10),
                _buildInfoCard('Courier Capacity', '50 kg'),
                const SizedBox(height: 10),
                _buildInfoCard('Departure', 'New York City'),
                const SizedBox(height: 10),
                _buildInfoCard('Arrival', 'San Francisco'),
              ],
            ),
            // Add the buttons at the bottom in a horizontal row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between buttons
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle Confirm Job button press
                      _showRequestDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Green color for Confirm Job
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Confirm Job',
                      style: TextStyle(fontSize: 16,
                          color: Colors.white
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Space between the buttons
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle Milestone button press
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddNewMilestone()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Blue color for Milestone
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Milestone',
                      style: TextStyle(fontSize: 16,
                          color: Colors.white
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
  // Function to show the alert dialog
  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Do you want to send a request?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('NO'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Add your logic to send the request here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request Sent')),
                );
                CustomDialog.showCustomDialog2(
                  context,
                  "Job request sent successfully"// Pass the BuildContext
                );

              },
              child: const Text('YES'),
            ),
          ],
        );
      },
    );
  }
}
