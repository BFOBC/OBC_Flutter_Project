
import 'package:broker_flutter_pp/data/notification/NotificationService.dart';
import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/main.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:broker_flutter_pp/ui/courier/MilestonesScreen.dart';
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
  String? emptyLegTBLRequestNodeID=" ";
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
                      _buildInfoCard('Start At', jobData.localStartDateTime ?? 'Not Available'),
                      const SizedBox(height: 10),
                      _buildInfoCard('End At', jobData.localEndDateTime ?? 'Not Available'),
                      const SizedBox(height: 10),
                      _buildInfoCard('Courier Capacity', jobData.courierCapacity ?? 'Not Available'),
                      const SizedBox(height: 10),
                      _buildInfoCard('Departure', jobData.departureLocation ?? 'Not Available'),
                      const SizedBox(height: 10),
                      _buildInfoCard('Arrival', jobData.arrivalLocation ?? 'Not Available'),
                    ],
                  ),
                  SafeArea(
                    minimum: const EdgeInsets.all(8), // thoda margin bhi de diya
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              emptyLegTBLRequestNodeID = jobData.emptyLegTBLNodeID.toString();
                              _showRequestDialog(
                                context,
                                'Do you want to accept Job?',
                                widget.emptyLegRequestID,
                                true,
                              );
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
                                context,
                                'Do you want to decline Job?',
                                widget.emptyLegRequestID,
                                false,
                              );
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
                                  builder: (context) => MilestonesScreen(
                                    emptyLegRequestID: widget.emptyLegRequestID,
                                  ),
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
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'Are you sure?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('No'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                handleJobAction(context, nodeID, acceptJob, widget.brokerID, widget.emptyLegRequestID);
              },
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Yes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> handleJobAction(BuildContext context, String nodeID, bool acceptJob, String brokerID, String emptyLegRequestID) async {
    // **Remove this extra pop** - dialog already closed in _showRequestDialog
    // Navigator.of(context).pop();

    final FirestoreService service = FirestoreService(context);
    final String jobStatus = acceptJob ? 'todo' : 'decline';
    service.updateJobStatus(nodeID, jobStatus);
    print('🔄 Updating job status...');
    print('📝 Node ID: $emptyLegTBLRequestNodeID');
    print('📌 New Status: $jobStatus');

    service.updateEmptyLegTableJobStatus(
      emptyLegTBLRequestNodeID.toString(),
      jobStatus,
    ).then((_) {
      print('✅ Job status updated successfully!');
    }).catchError((error) {
      print('❌ Failed to update job status: $error');
    });


/*
    final userInfo = await NotificationService.getUserFcmInfo(context);
    if (userInfo != null) {
      await NotificationService.sendNotification(
        toToken: userInfo['token']!,
        type: acceptJob ? "courier_accept" : "courier_reject",
        screen: "BrokerMissions",
        extraData: {"senderName": userInfo['name']},
      );
    }
*/
    final User currentUser = FirebaseAuth.instance.currentUser!;
    sendMilestoneCompletedNotification(jobStatus, brokerID, currentUser.uid.toString());


    final String email = currentUser.email ?? 'Unknown User';
    final String message = acceptJob
        ? "Your Job accepted by $email"
        : "Your Job declined by $email";

    CustomDialog.showCustomDialog3(
      context,
      acceptJob ? "Job Accepted successfully" : "Job Declined",
      onOkPressed: () {
        // Dialog will already be closed at this point

        service.createNotification(
          brokerID: brokerID,
          courierID: currentUser.uid,
          emptyLegRequestID: emptyLegRequestID,
          sentBy: "Courier",
          message: message,
        );

        // Navigate after a slight delay
        Future.delayed(const Duration(milliseconds: 200), () {
          navigatorKeyMain.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DrawerScreen()),
                (Route<dynamic> route) => false,
          );
        });
      },
    );

  }

  static Future<void> sendMilestoneCompletedNotification(String jobStatus,String brokerId, String courierId) async {
    // broker data
    final brokerData =
    await NotificationService.getBrokerNameAndTokenById(brokerId);

    // courier data
    final courierData =
    await NotificationService.getCourierNameAndTokenById(courierId);

    String title = '';
    String type = '';
    final courierName = courierData?['name'] ?? "Courier";

    if (jobStatus == 'todo') {
      title = 'Accepted Job';
    } else {
      title = 'Decline Job';
    }
    if (jobStatus == 'todo') {
      type = 'accepted_job';
    } else {
      type = 'decline_job';
    }


    print("brokerData: Notification sent $brokerData");

    if (brokerData != null) {
      await NotificationService.sendNotification(
        title: title,
        toToken: brokerData['token']!,
        type: type,
        screen: "BrokerMissionScreen",
        extraData: {"senderName": courierData?['name']},
      );
      print("DEBUG: Notification sent");
    }
  }

}
