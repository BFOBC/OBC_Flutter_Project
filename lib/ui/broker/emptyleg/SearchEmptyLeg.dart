import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightData {
  final DateTime startDateTime; // Change to DateTime
  final DateTime endDateTime; // Change to DateTime
  final String departureLocation;
  final String arrivalLocation;
  final String flightNumber;
  final String carrier;
  final int capacity;

  FlightData({
    required this.startDateTime,
    required this.endDateTime,
    required this.departureLocation,
    required this.arrivalLocation,
    required this.flightNumber,
    required this.carrier,
    required this.capacity,
  });
}

class SearchEmptyLegScreen extends StatefulWidget {
  const SearchEmptyLegScreen({super.key});

  @override
  _SearchEmptyLegScreenState createState() => _SearchEmptyLegScreenState();
}

class _SearchEmptyLegScreenState extends State<SearchEmptyLegScreen> {
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();

  List<FlightData> flights = [
    FlightData(
      startDateTime: DateTime.parse('2023-09-21T10:00:00Z'), // UTC format
      endDateTime: DateTime.parse('2023-09-21T12:00:00Z'), // UTC format
      departureLocation: 'ISB',
      arrivalLocation: 'KCH',
      flightNumber: 'PK-123',
      carrier: 'Pakistan International Airlines',
      capacity: 180,
    ),
    FlightData(
      startDateTime: DateTime.parse('2023-09-22T15:00:00Z'), // UTC format
      endDateTime: DateTime.parse('2023-09-22T17:00:00Z'), // UTC format
      departureLocation: 'LHR',
      arrivalLocation: 'LMR',
      flightNumber: 'PK-456',
      carrier: 'Pakistan International Airlines',
      capacity: 150,
    ),
  ];

  List<FlightData> filteredFlights = [];

  @override
  void initState() {
    super.initState();
    _searchController1.addListener(_filterFlights);
    _searchController2.addListener(_filterFlights);
  }

  void _filterFlights() {
    setState(() {
      filteredFlights = flights.where((flight) {
        final departureMatch = flight.departureLocation.contains(_searchController1.text.toUpperCase());
        final arrivalMatch = flight.arrivalLocation.contains(_searchController2.text.toUpperCase());
        return departureMatch || arrivalMatch;
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

// Function to display dialog with Flight Details
  void _showFlightDialog(FlightData flight) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // This will track whether the booking is made
            bool isBooked = false;

            return AlertDialog(
              titlePadding: EdgeInsets.zero, // Remove default padding for the close button
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
                  Text('Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(flight.startDateTime.toLocal())}'),
                  const SizedBox(height: 8),
                  Text('End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(flight.endDateTime.toLocal())}'),
                  const SizedBox(height: 8),
                  Text('Departure: ${flight.departureLocation}'),
                  const SizedBox(height: 8),
                  Text('Arrival: ${flight.arrivalLocation}'),
                  const SizedBox(height: 8),
                  Text('Capacity: ${flight.capacity}'),
                  const SizedBox(height: 20),
                  // Centered button with manual state change
                  Center(
                    child: isBooked
                        ? Icon(
                      Icons.airplane_ticket,
                      size: 50,
                      color: Colors.green,
                    )
                        : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isBooked = true; // Trigger button to icon change
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Book'),
                    ),
                  ),
                ],
              ),
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
            Container(
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
            ),
            const SizedBox(height: 40),

            // Filtered Items List
            Expanded(
              child: ListView.builder(
                itemCount: filteredFlights.length,
                itemBuilder: (context, index) {
                  final flight = filteredFlights[index];
                  double progress = _calculateProgress(flight.startDateTime, flight.endDateTime);

                  return GestureDetector(
                    onTap: () => _showFlightDialog(flight), // Show dialog on item click
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
                                          Text(DateFormat('yyyy-MM-dd HH:mm').format(flight.startDateTime.toLocal()), style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          const Text('End Time:', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(DateFormat('yyyy-MM-dd HH:mm').format(flight.endDateTime.toLocal()), style: const TextStyle(fontSize: 16)),
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
                                          Text(flight.departureLocation, style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text('Arrival:', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(flight.arrivalLocation, style: const TextStyle(fontSize: 16)),
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
}
