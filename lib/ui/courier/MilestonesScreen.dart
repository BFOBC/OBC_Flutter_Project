import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/courier/Milestone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MilestonesScreen extends StatefulWidget {
  final String emptyLegRequestID;

  // Constructor to accept the emptyLegRequestID
  MilestonesScreen({required this.emptyLegRequestID});

  @override
  _MilestonesScreenState createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Milestones'),
      ),
      body: StreamBuilder<List<Milestone>>(
        stream: getMilestonesByEmptyLegRequestID(widget.emptyLegRequestID),  // Using stream instead of future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No milestones found.'));
          }

          // Display the list of milestones
          List<Milestone> milestoneList = snapshot.data!;

          return ListView(
            children: [
              Card(
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Vertical progress line with milestones listed
                      Column(
                        children: [
                          for (int i = 0; i < milestoneList.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  // Left side: Circle and vertical line
                                  Column(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: milestoneList[i].milestoneStatus == "Done"
                                              ? Colors.green
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 2,
                                        height: 30, // Adjusted height for each milestone
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.rectangle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  // Right side: Milestone information
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Title: ', // Label for the title
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8), // Space between label and title
                                            Expanded(
                                              child: Text(
                                                milestoneList[i].title ?? 'No Title', // Title text
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Description: ${milestoneList[i].description ?? 'N/A'}'),
                                        const SizedBox(height: 4),
                                        Text('Start: ${milestoneList[i].milestoneStartDateTime ?? 'N/A'}'),
                                        const SizedBox(height: 4),
                                        Text('End: ${milestoneList[i].milestoneEndDateTime ?? 'N/A'}'),
                                        const SizedBox(height: 4),
                                        Text('Status: ${milestoneList[i].milestoneStatus ?? 'N/A'}'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the next screen when the FAB is pressed
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNewMilestone(emptyLegRequestID: widget.emptyLegRequestID)),
          );
          // Refresh milestones after returning from the AddNewMilestone screen
          setState(() {});
        }, // Plus sign icon
        backgroundColor: Colors.blue,
        child: Icon(Icons.add,color: Colors.white,), // FAB background color

      ),
    );
  }

  Stream<List<Milestone>> getMilestonesByEmptyLegRequestID(String emptyLegRequestID) {
    return FirebaseFirestore.instance
        .collection('milestones')
        .where('emptyLegRequestID', isEqualTo: emptyLegRequestID)
        .snapshots()  // Using snapshots for real-time data
        .map((snapshot) => snapshot.docs.map((doc) => Milestone.fromMap(doc.data())).toList());
  }

}
