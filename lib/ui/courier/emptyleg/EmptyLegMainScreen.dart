/*
import 'package:broker_flutter_pp/ui/courier/emptyleg/JobCardStackWidget.dart';
import 'package:flutter/material.dart';
import '../../common/charts/BarChartWidget.dart';
import '../../common/utils/CustomDialog.dart';
import '../../common/utils/DateTimePicker.dart';
import 'AddEmptyLegDialog.dart';
import 'CardStackWidget.dart';

class EmptyLegMainScreen extends StatefulWidget {
  const EmptyLegMainScreen({super.key});

  @override
  _EmptyLegMainScreenState createState() => _EmptyLegMainScreenState();
}

class _EmptyLegMainScreenState extends State<EmptyLegMainScreen> {
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
            const Expanded(
              child: BarChartWidget(), // Custom widget
            ),
            const SizedBox(height: 16),
            //if (flightDetailsList.isNotEmpty)
              //CardStackWidget(), // Custom widget
            const JobCardStackWidget(),

*/
/*            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showBottomSheet(context); // View user-entered flight details
              },
              child: const Text('View Flight Details'),
            ),*//*

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
          color: Colors.grey[200], // Gray background for the bottom sheet
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: userEnteredFlightDetailsList.map((flight) {
              int flightIndex = userEnteredFlightDetailsList.indexOf(flight);
              return Dismissible(
                key: Key(flight.flightNumber), // Unique key for each item
                direction: DismissDirection.endToStart, // Swipe from right to left
                background: Container(
                  color: Colors.red, // Red background for the delete action
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white), // Trash icon
                ),
                confirmDismiss: (direction) async {
                  // Show custom delete confirmation dialog
                  bool? confirmDeletion = await CustomDialog.showDeleteConfirmationDialog(
                      context, 'Are you sure you want to delete this job?'
                  );
                  return confirmDeletion; // Return true if confirmed, false if canceled
                },
                onDismissed: (direction) {
                  // Remove the item from the list if confirmed
                  setState(() {
                    userEnteredFlightDetailsList.removeAt(flightIndex);
                  });

                  // Optionally show a snackbar or confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Flight ${flight.flightNumber} deleted')),
                  );
                },
                child: Card(
                  child: Row(
                    children: [
                      // Blue vertical line
                      Container(
                        width: 10.0, // Adjust the width of the line
                        height: 70.0, // Adjust the height according to the content
                        color: Colors.blue,
                      ),
                      Expanded(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Blue background
                              foregroundColor: Colors.white, // White text
                            ),
                            child: const Text('View Details'),
                          ),
                        ),
                      ),
                    ],
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

  factory FlightDetails.fromMap(Map<String, dynamic> map) {
    return FlightDetails(
      userName: map['userName'] ?? 'Unknown',
      rating: (map['rating'] ?? 0).toDouble(),
      fromLocation: map['fromLocation'] ?? 'N/A',
      toLocation: map['toLocation'] ?? 'N/A',
      fromDateTime: map['fromDateTime'] ?? 'N/A',
      toDateTime: map['toDateTime'] ?? 'N/A',
      flightNumber: map['flightNumber'] ?? 'N/A',
      capacity: map['capacity'] ?? 0,
    );
  }
}
*/
