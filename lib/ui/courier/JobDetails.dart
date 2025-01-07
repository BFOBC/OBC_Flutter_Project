import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/res/strings.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/courier/CourierMap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../common/utils/CustomDialog.dart';
import 'Milestone.dart';

class JobDetails extends StatefulWidget {
  final String emptyLegRequestID;
  final String brokerID;

  const JobDetails({super.key, required this.emptyLegRequestID,required this.brokerID});

  @override
  _JobDetailsState createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> {
  late Future<EmptyLegRequest> jobDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch job details on initialization
    print('emptyLegRequestID----');
    print(widget.emptyLegRequestID);
    jobDetails = FirestoreService(context).getEmptyLegRequest(widget.emptyLegRequestID);
    jobDetails.whenComplete(() {
      setState(() {
        isLoading = false; // Stop loading when the data is fetched
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : FutureBuilder<EmptyLegRequest>(
          future: jobDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.hasData) {
              var jobData = snapshot.data!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Job Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard('Start At', jobData.startTimeDate ?? 'Not Available'),
                      const SizedBox(height: 10),
                      _buildInfoCard('End At', jobData.endTimeDate ?? 'Not Available'),
                      const SizedBox(height: 10),
                      _buildInfoCard('Courier Capacity', jobData.courierCapacity ?? 'Not Available'),
                      const SizedBox(height: 10),
                      _buildInfoCard('Departure', jobData.departureLocation ?? 'Not Available'),
                      const SizedBox(height: 10),
                      _buildInfoCard('Arrival', jobData.arrivalLocation ?? 'Not Available'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showRequestDialog(
                                context, 'Do you want to accept Job?', widget.emptyLegRequestID, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Accept Job',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showRequestDialog(
                                context, 'Do you want to decline Job?', widget.emptyLegRequestID, false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Decline Job',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddNewMilestone(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Milestone',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Center(child: Text('No Data Found'));
            }
          },
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

  void _showRequestDialog(BuildContext context, String message, String nodeID, bool acceptJob) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: Text(message),
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
                FirestoreService service = FirestoreService(context);
                service.updateJobStatus(nodeID, acceptJob ? 'Accept' : 'Decline');
                CustomDialog.showCustomDialog3(
                  context,
                  acceptJob ? "Job Accepted successfully" : "Job Declined",
                  onOkPressed: () {
                    FirestoreService firestoreService = FirestoreService(context);
                    User _currentUser = FirebaseAuth.instance.currentUser!;
                    String msg="Your Job accepted by  ${_currentUser.email}";

                    firestoreService.createNotification(brokerID: widget.brokerID,courierID: _currentUser.uid.toString(),emptyLegRequestID: widget.emptyLegRequestID,sentBy: "Courier",message: msg);


                    // Remove all screens and navigate to DrawerScreen
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/DrawerScreen',
                          (route) => false, // This ensures that all previous routes are removed
                    );
                  },
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
