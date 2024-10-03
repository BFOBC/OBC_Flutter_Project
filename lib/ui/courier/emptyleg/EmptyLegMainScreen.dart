import 'package:flutter/material.dart';
import '../../common/charts/BarChartWidget.dart';
import '../../common/utils/DateTimePicker.dart';
import 'AddEmptyLegDialog.dart';
import 'CardStackWidget.dart';

class EmptyLegMainScreen extends StatefulWidget {
  const EmptyLegMainScreen({Key? key}) : super(key: key);

  @override
  _EmptyLegMainScreenState createState() => _EmptyLegMainScreenState();
}

class _EmptyLegMainScreenState extends State<EmptyLegMainScreen> {
  // List of original flight details (existing flights)
  List<FlightDetails> flightDetailsList = [
    FlightDetails(
      fromLocation: 'City A',
      toLocation: 'City B',
      fromDateTime: '10/10/2024 10:00 AM',
      toDateTime: '10/10/2024 ',
      flightNumber: 'F123',
      capacity: '100kg',
      userName: 'John Doe',
      rating: 4,
    ),
  ];

  // List of user-entered flight details
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
                // Create a new FlightDetails object with default values
                FlightDetails newFlight = FlightDetails.empty();
                // Show the dialog to add a new flight (index -1 indicates new flight)
                _showFlightDetailsDialog(context, newFlight, -1,false);
              },
              child: Container(
                decoration: const BoxDecoration(
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
              child: BarChartWidget(), // Custom widget
            ),
            const SizedBox(height: 16),
            if (flightDetailsList.isNotEmpty)
              CardStackWidget(flightDetailsList: flightDetailsList), // Custom widget
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showBottomSheet(context); // View user-entered flight details
              },
              child: const Text('View Flight Details'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to display a bottom sheet for viewing flight details
  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: userEnteredFlightDetailsList.map((flight) {
              int flightIndex = userEnteredFlightDetailsList.indexOf(flight);
              return Card(
                child: ListTile(
                  title: Text('${flight.fromLocation} to ${flight.toLocation}'),
                  subtitle: Text('Flight: ${flight.flightNumber}, Capacity: ${flight.capacity}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Close the bottom sheet
                      Navigator.pop(context);
                      // Open the flight details dialog for existing flights
                      _showFlightDetailsDialog(context, flight, flightIndex, true);
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
  // Function to show a dialog for flight details (add/update)
  void _showFlightDetailsDialog(BuildContext context, FlightDetails flightDetails, int flightIndex, bool isFromAdd) {
    showDialog(
      context: context,
      builder: (context) => FlightDetailsDialog(flightDetails: flightDetails, flightIndex: flightIndex, isFromBottomSheet: isFromAdd),
    ).then((result) {
      if (result != null) {
        // Handle result based on 'action' (save/update/delete) from the dialog
        if (result['action'] == 'save') {
          setState(() {
            userEnteredFlightDetailsList.add(result['details']);
          });
          showSnackBar(context, 'Flight saved: ${result['details'].flightNumber}');
        } else if (result['action'] == 'update') {
          setState(() {
            if (flightIndex == -1) {
              // If new flight (index -1), add it to the list
              userEnteredFlightDetailsList.add(result['details']);
            } else {
              // Otherwise, update the existing flight
              userEnteredFlightDetailsList[result['index']] = result['details'];
            }
          });
          showSnackBar(context, 'Flight updated: ${result['details'].flightNumber}');
        } else if (result['action'] == 'delete') {
          setState(() {
            // Remove the flight from the list
            userEnteredFlightDetailsList.removeAt(result['index']);
          });
          showSnackBar(context, 'Flight deleted');
        }
      }
    });
  }



}

// Model class for FlightDetails
class FlightDetails {
  String fromLocation;
  String toLocation;
  String fromDateTime;
  String toDateTime;
  String flightNumber;
  String capacity;
  String userName;
  int rating;

  FlightDetails({
    required this.fromLocation,
    required this.toLocation,
    required this.fromDateTime,
    required this.toDateTime,
    required this.flightNumber,
    required this.capacity,
    required this.userName,
    required this.rating,
  });

  // Factory constructor for an empty flight (for new entries)
  factory FlightDetails.empty() {
    return FlightDetails(
      fromLocation: '',
      toLocation: '',
      fromDateTime: '',
      toDateTime: '',
      flightNumber: '',
      capacity: '',
      userName: '',
      rating: 0,
    );
  }
}
