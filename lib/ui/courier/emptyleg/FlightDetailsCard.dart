import 'package:broker_flutter_pp/ui/courier/emptyleg/EmptyLegMainScreen.dart';
import 'package:flutter/material.dart';


class FlightDetailsCard extends StatelessWidget {
  final FlightDetails flightDetails;
  final VoidCallback onViewDetails;

  const FlightDetailsCard({required this.flightDetails, required this.onViewDetails, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Departure: ${flightDetails.fromLocation}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Arrival: ${flightDetails.toLocation}'),
            const SizedBox(height: 8),
            Text('Courier ID: ${flightDetails.flightNumber}'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onViewDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Rectangle blue background
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
