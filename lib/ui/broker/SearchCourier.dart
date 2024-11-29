import 'dart:math';
import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Visa.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/broker/CircularRating.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../res/custom_colors.dart';
import 'BasicInfo.dart';
import 'ManageLegsAndMilestones.dart';
import 'Passports.dart';  // Import the Passports widget
import 'Visas.dart';      // Import the Visas widget

class SearchCourier extends StatefulWidget {
  final String userName;
  final double rating;
  final String userImage;

  const SearchCourier({
    super.key,
    required this.userName,
    required this.rating,
    required this.userImage,
  });

  @override
  _SearchCourierState createState() => _SearchCourierState();
}

class _SearchCourierState extends State<SearchCourier> {
  bool _showPieChart = false;
  bool _showProfile = true; // Set default to true to show BasicInfo
  bool _showPassports = false;
  bool _showVisas = false;

  // Sample data for the pie chart
  final Map<String, double> dataMap = {
    "Negative": 40,
    "Positive": 30,
    "Neutral": 30,
  };
  var rating = Random().nextDouble() * 5; // Random rating between 0 and 5

  final List<Color> colorList = [
    Colors.red,
    Colors.green,
    Colors.blue,
  ];

  // Toggle state for the buttons
  final List<bool> _selectedToggle = [true, false, false, false];

  // Define the toggle button labels
  final List<String> _toggleText = ['Basic Info', 'Passports', 'Visas', 'Rating'];

  // Handle toggle button press
  void _onTogglePressed(int index) {
    setState(() {
      for (int i = 0; i < _selectedToggle.length; i++) {
        _selectedToggle[i] = i == index;
      }

      // Update the displayed content based on the selected toggle
      _showProfile = index == 0;
      _showPassports = index == 1;
      _showVisas = index == 2;
      _showPieChart = index == 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courier Name'),
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

                // Centered Text for Name and Rating Stars
                Center(
                  child: RatingBarIndicator(
                    rating: rating, // User's rating
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 25.0,
                    direction: Axis.horizontal,
                  ),
                ),
                const SizedBox(height: 10),

                // Scrollable Toggle Buttons for navigation
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ToggleButtons(
                    isSelected: _selectedToggle,
                    onPressed: _onTogglePressed,
                    borderRadius: BorderRadius.circular(10),
                    selectedBorderColor: Colors.grey,
                    selectedColor: Colors.white,
                    fillColor: Palette.primaryColor, // Use your custom palette
                    color: Colors.black,
                    constraints: const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                    children: _toggleText.map((text) => Text(text)).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Conditionally show Profile, Passports, Visas, or Pie Chart
                if (_showProfile)
                  BasicInfo(name: widget.userName),
                if (_showPassports)
                  Passports(
                    passports: [
                      Passport(
                        countryName: '',
                        passportNumber: 'A123456789',
                        issueDate: '2020-01-01',
                        expiryDate: '2030-01-01',
                      ),
                      Passport(
                        countryName: 'Jane Doe',
                        passportNumber: 'B987654321',
                        issueDate: '2021-02-15',
                        expiryDate: '2031-02-15',
                      ),
                    ],
                  ),
                if (_showVisas)
                  Visas(
                    visas: [
/*                      Visa(
                        country: 'Country A',
                        countryFlagUrl: 'https://example.com/flagA.png',
                        visaExpiryDate: '2025-12-31',
                        visaIssueDate: '2023-01-01',
                      ),*/
                      Visa(
                        countryName: 'Country B',
                        expiryDate: '2026-06-30',
                      ),
                    ],
                  ),
                if (_showPieChart)
                  CircularRating(
                    dataMap: dataMap,
                    colorList: colorList,
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 200, // Set a fixed width for the button
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageLegsAndMilestones(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.secondaryColor,
                    // Set the button color to green
                    foregroundColor: Colors.white,
                    // Set the text color to white
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0), // Rounded corners
                    ),
                  ),
                  child: const Text('Place the Job'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
