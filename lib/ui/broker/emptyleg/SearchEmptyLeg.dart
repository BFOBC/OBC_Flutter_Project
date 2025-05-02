import 'package:broker_flutter_pp/data/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:broker_flutter_pp/ui/chat/ChatListScreen.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String courierID = "";
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();

  List<FlightData> flights = [];
  List<FlightData> filteredFlights = [];
  List<AirportModel> fromAirportSuggestions = []; // Suggestions for "From Location"
  List<AirportModel> toAirportSuggestions = []; // Suggestions for "To Location"
  AirportModel? selectedFromAirport;
  AirportModel? selectedToAirport;
  @override
  void initState() {
    super.initState();
    _fetchFlights(); // Fetch model from Firestore when screen initializes
  }
  // Fetch airports that match the query for From Location
  Future<void> _fetchFromAirportData(String query) async {
    if (query.isNotEmpty) {
      try {
        final airports = await fetchAirportsFromDatabase(query);
        setState(() {
          fromAirportSuggestions = airports;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching airports: $e')));
      }
    } else {
      setState(() {
        fromAirportSuggestions = [];
      });
    }
  }
  // Fetch airports that match the query for To Location
  Future<void> _fetchToAirportData(String query) async {
    if (query.isNotEmpty) {
      try {
        final airports = await fetchAirportsFromDatabase(query);
        setState(() {
          toAirportSuggestions = airports;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching airports: $e')));
      }
    } else {
      setState(() {
        toAirportSuggestions = [];
      });
    }
  }
  Future<List<AirportModel>> fetchAirportsFromDatabase(String query) async {
    final dbHelper = DatabaseOperation();
    try {
      List<AirportModel> airports = await dbHelper.fetchAirportsFromDatabase(query);
      return airports;
    } catch (e) {
      print('Error _fetchAirports $e');
      return [];
    }
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

          final fromDateTime = data['fromDateTime'] is Timestamp
              ? (data['fromDateTime'] as Timestamp).toDate()
              : DateTime.parse(data['fromDateTime']);

          final toDateTime = data['toDateTime'] is Timestamp
              ? (data['toDateTime'] as Timestamp).toDate()
              : DateTime.parse(data['toDateTime']);

          final capacity = data['capacity'] is int
              ? data['capacity']
              : int.tryParse(data['capacity']) ?? 0;

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
          filteredFlights = flightList; // Initially, show all flights
        });
      });
    } catch (e) {
      print("Error fetching flights: $e");
    }
  }

  void _filterFlights() {
    final departureQuery = _searchController1.text.toLowerCase();
    final arrivalQuery = _searchController2.text.toLowerCase();

    setState(() {
      filteredFlights = flights.where((flight) {
        final matchesDeparture = flight.fromLocation.toLowerCase().contains(departureQuery);
        final matchesArrival = flight.toLocation.toLowerCase().contains(arrivalQuery);
        return matchesDeparture && matchesArrival;
      }).toList();
    });
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Rounded corners
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(20), // Padding for content
              title: Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(25.0),
                    child: Text(
                      'Empty Leg Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flight Number:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Bold label
                  Text('${flight.flightNumber}', style: TextStyle(fontSize: 16)), // Regular value
                  const SizedBox(height: 8),

                  Text('Start Time:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Bold label
                  Text('${DateFormat('yyyy-MM-dd HH:mm').format(flight.fromDateTime.toLocal())}', style: TextStyle(fontSize: 16)), // Regular value
                  const SizedBox(height: 8),

                  Text('End Time:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Bold label
                  Text('${DateFormat('yyyy-MM-dd HH:mm').format(flight.toDateTime.toLocal())}', style: TextStyle(fontSize: 16)), // Regular value
                  const SizedBox(height: 8),

                  Text('Departure:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Bold label
                  Text('${flight.fromLocation}', style: TextStyle(fontSize: 16)), // Regular value
                  const SizedBox(height: 8),

                  Text('Arrival:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Bold label
                  Text('${flight.toLocation}', style: TextStyle(fontSize: 16)), // Regular value
                  const SizedBox(height: 8),

                  Text('Capacity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Bold label
                  Text('${flight.capacity}', style: TextStyle(fontSize: 16)), // Regular value
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Green background
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Book',
                        style: TextStyle(fontSize: 14,color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatDetailScreen(userID: courierID)),
                      ); // Navigate to chat screen
                    },
                    backgroundColor: Colors.blue,
                    mini: true, // Makes it smaller
                    child: CircleAvatar(
                      radius: 15, // Adjust size for a better fit
                      backgroundColor: Colors.white, // Optional: Adds a contrast border
                      child: Icon(Icons.chat, size: 20, color: Colors.blue),
                    ),
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
            // Arrival Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.green, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController2,
                decoration: InputDecoration(
                  hintText: 'Arrival',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController2.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      _searchController2.clear(); // Clear text input
                    },
                  )
                      : null, // Don't show the icon if text is empty
                ),
                onChanged: (String value) {
                  print("Arrival text changed: $value");
                  _fetchFromAirportData(value);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Allows only letters and spaces
                ],
              ),
            ),

            // Show suggestions below 'From Location'
            if (fromAirportSuggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: fromAirportSuggestions.length,
                itemBuilder: (context, index) {
                  final airport = fromAirportSuggestions[index];
                  return ListTile(
                    title: Text(airport.name ?? 'Unknown'),
                    onTap: () {
                      setState(() {
                        _searchController2.text = airport.name ?? '';
                        selectedFromAirport = airport;
                        fromAirportSuggestions = [];
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 15),

            // Departure Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.green, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController1,
                decoration:  InputDecoration(
                  hintText: 'Departure',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController1.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      _searchController1.clear(); // Clear text input
                    },
                  )
                      : null, // Don't show the icon if text is empty
                ),
                onChanged: (String value) {
                  // This callback is triggered every time the user types.
                  print("Departure text changed: $value");
                  _fetchToAirportData(value);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Allows only letters and spaces
                ],
              ),
            ),
            // Show suggestions below 'From Location'
            if (toAirportSuggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: toAirportSuggestions.length,
                itemBuilder: (context, index) {
                  final airport = toAirportSuggestions[index];
                  return ListTile(
                    title: Text(airport.name ?? 'Unknown'),
                    onTap: () {
                      setState(() {
                        _searchController1.text = airport.name ?? '';
                        selectedToAirport = airport;
                        toAirportSuggestions = [];
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 15),
            // Search Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end, // بٹن دائیں طرف رکھنے کے لیے
              children: [
                SizedBox(
                  width: 120,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _filterFlights,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // بٹنوں کے درمیان فاصلہ
                SizedBox(
                  width: 120, // برابر width
                  height: 40, // برابر height
                  child: ElevatedButton(
                    onPressed: _resetFlights,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'All',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),


            const SizedBox(height: 10),

            // Filtered Items List
            // Filtered Items List
            Expanded(
              child: filteredFlights.isEmpty
                  ? Center(
                child: Text(
                  'No Data Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              )
                  : ListView.builder(
                itemCount: filteredFlights.length,
                itemBuilder: (context, index) {
                  final flight = filteredFlights[index];
                  double progress = _calculateProgress(flight.fromDateTime, flight.toDateTime);

                  return GestureDetector(
                    onTap: () => _showFlightDialog(context, flight),
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Blue Vertical Line on Left
                            Container(
                              width: 8,
                              height: 120,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),

                            // Flight Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Arrival:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(flight.toLocation, style: const TextStyle(fontSize: 16)),

                                  const SizedBox(height: 8),

                                  Text('Departure:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(flight.fromLocation, style: const TextStyle(fontSize: 16)),

                                  const SizedBox(height: 8),

                                  // Progress Bar
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
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

// Function to Reset Flights List
  void _resetFlights() {
    setState(() {
      _searchController1.clear();
      _searchController2.clear();
      filteredFlights = List.from(flights); // Reset the list to original flights
    });
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
     String currentDateTime= DateTime.now().toString();
    String UTCTime=  convertToUTCFromCustomFormat(currentDateTime.toString());
      await FirebaseFirestore.instance.collection('emptyLegRequests').doc(nodeID).set({
        'emptyLegRequestID': nodeID, // Add nodeID explicitly
        'brokerID': brokerID,
        'status': "pending",
        'requestDateTime':UTCTime,
        'courierID': courierID,
      });

      CustomDialog.showCustomDialog2(context, "Request Successfully");
    } catch (e) {
      CustomDialog.showCustomDialog2(context, "Error: ${e.toString()}");
    }
  }
}


