import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CardStackWidget extends StatelessWidget {
  const CardStackWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8), // Spacing between title and cards
        SizedBox(
          height: 120, // Fixed height for the card stack
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(5, (index) => _buildCard(index)),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(right: 4.0),
      child: Container(
        width: 300, // Fixed width for cards
        padding: const EdgeInsets.all(4.0), // Slightly reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(), // Add header with image, name, rating, and chat button
            SizedBox(height: 2), // Spacing below the header
            Text(
              'Flight #${index + 1}', // Dynamic flight number
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4), // Reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Departure: City A',
                    style: TextStyle(fontSize: 12), // Smaller font size
                  ),
                  Text(
                    'Arrival: City B',
                    style: TextStyle(fontSize: 12), // Smaller font size
                  ),
                  Text(
                    'Price: \$${(index + 1) * 100}', // Dynamic price
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Smaller font size and bold
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
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
                'User Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ), // User name
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16), // Star icon
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  Icon(Icons.star, color: Colors.grey, size: 16), // Grey star for rating
                  Icon(Icons.star, color: Colors.grey, size: 16),
                ],
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
