import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:broker_flutter_pp/ui/broker/CircularRating.dart'; // Assuming it's correctly imported
import 'package:broker_flutter_pp/ui/broker/BasicInfo.dart';

import 'BrokerBasicInfo.dart';
import 'JobDetails.dart'; // Assuming BasicInfo widget is implemented

class SelectBroker extends StatefulWidget {
  final String userName;
  final double rating;
  final String userImage;

  const SelectBroker({
    super.key,
    required this.userName,
    required this.rating,
    required this.userImage,
  });

  @override
  _SearchCourierState createState() => _SearchCourierState();
}

class _SearchCourierState extends State<SelectBroker> {
  bool _showProfile = true;  // By default, show Profile
  bool _showPieChart = false; // By default, don't show Pie Chart

  final Map<String, double> dataMap = {
    "Negative": 40,
    "Positive": 30,
    "Neutral": 30,
  };
  var rating = Random().nextDouble() * 5;

  final List<Color> colorList = [
    Colors.red,
    Colors.green,
    Colors.blue,
  ];

  final List<bool> _selectedToggle = [true, false]; // Default is 'Basic Info' selected
  final List<String> _toggleText = ['Basic Info', 'Rating'];

  void _onTogglePressed(int index) {
    setState(() {
      // Toggle selection logic
      for (int i = 0; i < _selectedToggle.length; i++) {
        _selectedToggle[i] = i == index;
      }

      // Update the view based on selected toggle
      _showProfile = index == 0;
      _showPieChart = index == 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broker Name'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Image
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.userImage),
                ),
                const SizedBox(height: 10),

                // Broker Number label and Rating
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Broker Number: 123456', // Example Broker Number
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      RatingBarIndicator(
                        rating: rating, // User's rating
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 25.0,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),

                // Scrollable Toggle Buttons for navigation
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ToggleButtons(
                    isSelected: _selectedToggle,
                    onPressed: _onTogglePressed,
                    borderRadius: BorderRadius.circular(10),
                    selectedBorderColor: Colors.grey,
                    selectedColor: Colors.white,
                    fillColor: Colors.green, // Use your custom palette
                    color: Colors.black,
                    constraints: const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                    children: _toggleText.map((text) => Text(text)).toList(),
                  ),
                ),

                // Horizontal Line with custom margins
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 30.0),
                  child: Divider(
                    color: Colors.grey,
                    thickness: 1.0,
                  ),
                ),

                // Conditionally show Profile or Circular Chart
                if (_showProfile)
                  BrokerBasicInfo(name: widget.userName),  // Show Basic Info
                if (_showPieChart)

                Center( // Center the CircularRating widget
                    child: CircularRating(
                      dataMap: dataMap,
                      colorList: colorList,
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    // Add your onPressed functionality here
                    // Navigate to JobDetails screen on button click
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobDetails()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text('View Job Details'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
