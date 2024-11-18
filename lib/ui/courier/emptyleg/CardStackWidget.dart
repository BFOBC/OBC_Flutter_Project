import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'EmptyLegMainScreen.dart';

class CardStackWidget extends StatelessWidget {
  final List<FlightDetails> flightDetailsList;

  const CardStackWidget({super.key, required this.flightDetailsList});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; // Get screen height
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8), // Spacing between title and cards
        SizedBox(
          height: screenHeight * 0.25, // Adjust height based on screen size
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: flightDetailsList.length,
            itemBuilder: (context, index) {
              return _buildCard(flightDetailsList[index], screenWidth);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(FlightDetails details, double screenWidth) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(right: 8.0),
      child: Container(
        width: screenWidth * 0.7, // Adjusted width for cards
        padding: const EdgeInsets.all(8.0), // Padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(details), // Add header with user details
            SizedBox(height: 8), // Spacing below the header
            Expanded(
              child: SingleChildScrollView(
                child: _buildFlightDetails(details), // Flight details
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightDetails(FlightDetails details) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // From Label and Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text('Location: ${details.fromLocation}', style: TextStyle(fontSize: 12)),
                  Text('Date: ${details.fromDateTime}', style: TextStyle(fontSize: 12)),
                  Text('Time: ${details.toDateTime}', style: TextStyle(fontSize: 12)),
                  Text('Flight Number: ${details.flightNumber}', style: TextStyle(fontSize: 12)),
                  Text('Capacity: ${details.capacity}', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            SizedBox(width: 16), // Space between From and To columns
            // To Label and Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'To:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text('Location: ${details.toLocation}', style: TextStyle(fontSize: 12)),
                  Text('Date: ${details.toDateTime}', style: TextStyle(fontSize: 12)),
                  Text('Time: ${details.fromDateTime}', style: TextStyle(fontSize: 12)),
                  Text('Flight Number: ${details.flightNumber}', style: TextStyle(fontSize: 12)),
                  Text('Capacity: ${details.capacity}', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardHeader(FlightDetails details) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/avatar.png', // Replace with your image asset path
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 8), // Spacing between image and text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.userName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ), // User name
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < details.rating ? Icons.star : Icons.star_border,
                    color: index < details.rating ? Colors.amber : Colors.grey,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.chat, color: Colors.blue),
          onPressed: () {
            // Action for chat button
            // Navigate to chat screen or show chat dialog
          },
        ),
      ],
    );
  }
}
