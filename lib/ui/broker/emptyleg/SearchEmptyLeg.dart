import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:broker_flutter_pp/ui/chat/ChatListScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/utils/CustomDialog.dart';

class FlightData {
  final DateTime fromDateTime; // Change to DateTime
  final DateTime toDateTime; // Change to DateTime
  final String fromLocation;
  final String toLocation;
  final String flightNumber;
  final int capacity;

  FlightData({
    required this.fromDateTime,
    required this.toDateTime,
    required this.fromLocation,
    required this.toLocation,
    required this.flightNumber,
    required this.capacity,
  });
}

class SearchEmptyLegScreen extends StatefulWidget {
  SearchEmptyLegScreen({super.key});
  @override
  _SearchEmptyLegScreenState createState() => _SearchEmptyLegScreenState();
}

class _SearchEmptyLegScreenState extends State<SearchEmptyLegScreen> {
  String courierID="";
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  
  List<FlightData> flights = [];
  List<FlightData> filteredFlights = [];

  @override
  void initState() {
    super.initState();
    _fetchFlights(); // Fetch model from Firestore when screen initializes
  }

  void _fetchFlights() {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not authenticated');
      return;
    }

    FirebaseFirestore.instance.collection('emptyLegs').snapshots().listen((snapshot) {
      final List<FlightData> flightList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

         courierID = data['courierID'] is String
            ? (data['courierID'] as String)
            : data['courierID'].toString();

        // Safely parse fromDateTime and toDateTime
        final fromDateTime = data['fromDateTime'] is Timestamp
            ? (data['fromDateTime'] as Timestamp).toDate()
            : DateTime.parse(data['fromDateTime']);

        final toDateTime = data['toDateTime'] is Timestamp
            ? (data['toDateTime'] as Timestamp).toDate()
            : DateTime.parse(data['toDateTime']);

        // Safely parse capacity (handle both int and String)
        final capacity = data['capacity'] is int
            ? data['capacity']
            : int.tryParse(data['capacity']) ?? 0; // Default to 0 if parsing fails

        return FlightData(
          fromDateTime: fromDateTime,
          toDateTime: toDateTime,
          fromLocation: data['fromLocation'],
          toLocation: data['toLocation'],
          flightNumber: data['flightNumber'],
          capacity: capacity,
        );
      }).toList();

      setState(() {
        flights = flightList;
        filteredFlights = flightList;
      });
    });
  } catch (e) {
    print("Error fetching flights: $e");
  }
}


  double _calculateProgress(DateTime start, DateTime end) {
    final DateTime now = DateTime.now().toUtc();

    if (now.isBefore(start)) {
      return 0.0;
    } else if (now.isAfter(end)) {
      return 1.0;
    }
    return (now.difference(start).inMinutes / end.difference(start).inMinutes);
  }

  void _showFlightDialog(BuildContext context, FlightData flight) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isBooked = false;

            return AlertDialog(
              titlePadding: EdgeInsets.zero,
              title: Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Flight Details'),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                      },
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flight Number: ${flight.flightNumber}'),
                  const SizedBox(height: 8),
                  Text('Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(flight.fromDateTime.toLocal())}'),
                  const SizedBox(height: 8),
                  Text('End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(flight.toDateTime.toLocal())}'),
                  const SizedBox(height: 8),
                  Text('Departure: ${flight.fromLocation}'),
                  const SizedBox(height: 8),
                  Text('Arrival: ${flight.toLocation}'),
                  const SizedBox(height: 8),
                  Text('Capacity: ${flight.capacity}'),
                  const SizedBox(height: 20),
                  Center(
                    child: isBooked
                        ? const Icon(
                      Icons.airplane_ticket,
                      size: 50,
                      color: Colors.green,
                    )
                        : ElevatedButton(
                      onPressed: () {
                        _sendBookRequest();
                        setState(() {
                          isBooked = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Book'),
                    ),
                  ),
                ],
              ),
              actions: [
                // Chat button at the bottom-right of the dialog
                Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  ChatDetailScreen(userID:courierID))); // Navigate to chat screen
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.chat),
                  ),
                ),
              ],
            );
          },
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Departure Search Bar
           /* Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.green, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController1,
                decoration: const InputDecoration(
                  hintText: 'Departure',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Arrival Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.green, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController2,
                decoration: const InputDecoration(
                  hintText: 'Arrival',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),*/
            const SizedBox(height: 40),

            // Filtered Items List
            Expanded(
              child: ListView.builder(
                itemCount: filteredFlights.length,
                itemBuilder: (context, index) {
                  final flight = filteredFlights[index];
                  double progress = _calculateProgress(flight.fromDateTime, flight.toDateTime);

                  return GestureDetector(
                    onTap: () => _showFlightDialog(context,flight), // Show dialog on item click
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 80,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          const Text('Start Time:', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(DateFormat('yyyy-MM-dd HH:mm').format(flight.fromDateTime.toLocal()), style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          const Text('End Time:', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(DateFormat('yyyy-MM-dd HH:mm').format(flight.toDateTime.toLocal()), style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text('Departure:', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(flight.fromLocation, style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text('Arrival:', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(flight.toLocation, style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8), // Space between content and progress bar
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              color: Colors.blueAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController1.dispose();
    _searchController2.dispose();
    super.dispose();
  }
  String getCurrentUserId() {
    // Replace this with your actual logic to retrieve the user ID
    return FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  }

  Future<void> _sendBookRequest() async {
    try {
      String brokerID = getCurrentUserId();
      // Generate a custom nodeID (you can replace this with any unique value generator)
      String nodeID = FirebaseFirestore.instance.collection('emptyLegRequests').doc().id;

      await FirebaseFirestore.instance.collection('emptyLegRequests').doc(nodeID).set({
        'nodeID': nodeID, // Add nodeID explicitly
        'brokerID': brokerID,
        'status': false,
        'requestDateTime': DateTime.now().toIso8601String(),
        'courierID': courierID,
      });

      CustomDialog.showCustomDialog2(context, "Request Successfully");
    } catch (e) {
      CustomDialog.showCustomDialog2(context, "Error: ${e.toString()}");
    }
  }

}
