import 'package:flutter/material.dart';
import '../../common/charts/BarChartWidget.dart';
import 'AddEmptyLegDialog.dart';
import 'CardStackWidget.dart';

class EmptyLegMainScreen extends StatefulWidget {
  const EmptyLegMainScreen({Key? key}) : super(key: key);

  @override
  _EmptyLegMainScreenState createState() => _EmptyLegMainScreenState();
}

class _EmptyLegMainScreenState extends State<EmptyLegMainScreen> {
  // Original flight details list
  List<FlightDetails> flightDetailsList = [
    FlightDetails(
      fromLocation: 'City A',
      toLocation: 'City B',
      fromDate: '10/10/2024',
      fromTime: '10:00 AM',
      toDate: '10/10/2024',
      toTime: '12:00 PM',
      flightNumber: 'F123',
      capacity: '100kg',
      userName: 'John Doe',
      rating: 4,
    ),
  ];

  // New list to store user-entered flight details
  List<FlightDetails> userEnteredFlightDetailsList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                _showFlightDetailsDialog(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: BarChartWidget(),
            ),
            const SizedBox(height: 16),
            if (flightDetailsList.isNotEmpty)
              CardStackWidget(flightDetailsList: flightDetailsList),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showBottomSheet(context);
              },
              child: const Text('View Flight Details'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlightDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FlightDetailsDialog(),
    ).then((result) {
      if (result != null && result is FlightDetails) {
        // Add user-entered flight details and refresh UI
        setState(() {
          userEnteredFlightDetailsList.add(result);
        });
        print('Added flight: ${result.flightNumber}');
        _showSnackBar('Added flight: ${result.flightNumber}');
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: userEnteredFlightDetailsList.map((flight) {
              return Card(
                child: ListTile(
                  title: Text('${flight.fromLocation} to ${flight.toLocation}'),
                  subtitle: Text('Flight: ${flight.flightNumber}, Capacity: ${flight.capacity}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Handle "View Details" button press
                    },
                    child: const Text('View Details'),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class FlightDetails {
  final String fromLocation;
  final String toLocation;
  final String fromDate;
  final String fromTime;
  final String toDate;
  final String toTime;
  final String flightNumber;
  final String capacity;
  final String userName;
  final int rating;

  FlightDetails({
    required this.fromLocation,
    required this.toLocation,
    required this.fromDate,
    required this.fromTime,
    required this.toDate,
    required this.toTime,
    required this.flightNumber,
    required this.capacity,
    required this.userName,
    required this.rating,
  });
}
