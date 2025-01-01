import 'dart:math';
import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Visa.dart';
import 'package:broker_flutter_pp/ui/common/utils/AuthUtils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/broker/CircularRating.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../res/custom_colors.dart';
import '../courier/models/CourierProfileData.dart';
import 'BasicInfo.dart';
import 'ManageLegsAndMilestones.dart';
import 'Passports.dart';  // Import the Passports widget
import 'Visas.dart';      // Import the Visas widget

class SearchCourier extends StatefulWidget {

  String courierKey;

   SearchCourier({
    super.key,
    required this.courierKey,
  });

  @override
  _SearchCourierState createState() => _SearchCourierState();
}

class _SearchCourierState extends State<SearchCourier> {
  bool _showPieChart = false;
  bool _showProfile = true; // Set default to true to show BasicInfo
  bool _showPassports = false;
  bool _showVisas = false;

  bool _isLoading = true;
  late String userName = '';
  late String email = '';
  late String userImage = '';
  late double rating = 5;
  late List<Passport> passports;
  late List<Visa> visas;
  late CourierProfileData courierProfile;
  // Sample data for the pie chart
  final Map<String, double> dataMap = {
    "Negative": 40,
    "Positive": 30,
    "Neutral": 30,
  };

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
  void initState() {
    super.initState();
    widget.courierKey=widget.courierKey.replaceAll(RegExp(r'[\[\]<>]'), '').replaceAll("'", "");
    fetchCourierData(); // Fetch data when the screen is initialized
  }

  // Fetch courier data from Firestore
  Future<void> fetchCourierData() async {
    try {
      // Check if courierKey is valid (non-empty)
      if (widget.courierKey.isEmpty) {
        print("Courier key is empty!");
        setState(() {
          _isLoading = false;
        });
        return; // Early return if the courierKey is invalid (empty)
      }
      print("Courier");
      String cleanCourierKey = widget.courierKey.replaceAll(RegExp(r'[\[\]<>]'), '').replaceAll("'", "");
      print('Cleaned Courier Key: $cleanCourierKey');

      DocumentSnapshot courierDoc = await FirebaseFirestore.instance
          .collection('courier')
          .doc(cleanCourierKey)
          .get();

      if (courierDoc.exists) {
        var data = courierDoc.data() as Map<String, dynamic>;
        // Create the CourierProfileData model from Firestore data
        courierProfile = CourierProfileData.fromMap(data);
        // Log the data received from Firestore
        print("Courier Data fetched successfully: $data");

        setState(() {
          userName = data['name'] ?? 'Courier';
          userImage = data['userImage'] ?? '';
          rating = data['rating']?.toDouble() ?? 5.0;
          passports = (data['passports'] as List?)
              ?.map((passport) => Passport.fromMap(passport))
              .toList() ??
              [];
          visas = (data['visas'] as List?)
              ?.map((visa) => Visa.fromMap(visa))
              .toList() ??
              [];
          _isLoading = false; // Set loading to false once data is fetched
        });
      } else {
        // Handle no data case
        setState(() {
          _isLoading = false;
        });
        print("No courier found with this key.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching courier data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('$userName'),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(), // Show progress bar while loading
      )
          : Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Image
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(userImage),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Left aur right margin dono sides par
                  child: Align(
                    alignment: Alignment.center, // Ensure content left-aligned rahe
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ToggleButtons(
                        isSelected: _selectedToggle,
                        onPressed: _onTogglePressed,
                        borderRadius: BorderRadius.circular(10),
                        selectedBorderColor: Colors.grey,
                        selectedColor: Colors.white,
                        fillColor: Palette.primaryColor, // Use your custom palette
                        color: Colors.black,
                        constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
                        children: _toggleText.map((text) => Text(text)).toList(),
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 10),

                // Conditionally show Profile, Passports, Visas, or Pie Chart
                if (_showProfile) BasicInfo(courierProfileData :courierProfile),
                if (_showPassports)
                  Passports(
                    passports: passports,
                  ),
                if (_showVisas)
                  Visas(
                    visas: visas,
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
                        builder: (context) =>  ManageLegsAndMilestones(brokerKey: AuthUtils.getCurrentUserId2().toString(),courierKey:widget.courierKey),
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

