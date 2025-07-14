import 'dart:math';
import 'package:broker_flutter_pp/ui/broker/mission/PlaceNewJob.dart';
import 'package:broker_flutter_pp/ui/broker/requestscreens/Submission.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Visa.dart';
import 'package:broker_flutter_pp/ui/common/utils/AuthUtils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/broker/CircularRating.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../res/custom_colors.dart';
import '../courier/models/CourierProfileData.dart';
import 'requestscreens/BasicInfo.dart';
import 'mission/ManageLegsAndMilestones.dart';
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
  String userName = '';
  String email = '';
  String userImage = '';
  double rating = 5;
  List<Passport> passports = [];
  List<Visa> visas = [];
  CourierProfileData? courierProfile; // Nullable field, initialized to null

  // Sample model for the pie chart
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
    widget.courierKey = widget.courierKey.replaceAll(RegExp(r'[\[\]<>]'), '').replaceAll("'", "");
    fetchCourierData(); // Fetch model when the screen is initialized
  }

  // Fetch courier model from Firestore
  Future<void> fetchCourierData() async {
    try {
      // Check if courierKey is valid (non-empty)
      if (widget.courierKey.isEmpty) {
        print("Courier key is empty!");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String cleanCourierKey = widget.courierKey.replaceAll(RegExp(r'[\[\]<>]'), '').replaceAll("'", "");
      print('Cleaned Courier Key: $cleanCourierKey');

      DocumentSnapshot courierDoc = await FirebaseFirestore.instance
          .collection('courier')
          .doc(cleanCourierKey)
          .get();

      if (courierDoc.exists) {
        var data = courierDoc.data() as Map<String, dynamic>;

        setState(() {
          // Handle possible null values by setting default values (e.g., 'N/A' or an empty string)
          courierProfile = CourierProfileData.fromMap(data);
          userName = data['name'] ?? 'Courier';  // Use 'Courier' if 'name' is null
          userImage = data['userImage'] ?? 'N/A';  // Use 'N/A' if 'userImage' is null
          rating = data['rating']?.toDouble() ?? 5.0;  // Default rating to 5 if null
          passports = (data['passports'] as List?)?.map((passport) => Passport.fromMap(passport)).toList() ?? [];
          visas = (data['visas'] as List?)?.map((visa) => Visa.fromMap(visa)).toList() ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print("No courier found with this key.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching courier model: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
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
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(userImage),
                ),
                const SizedBox(height: 10),
                Center(
                  child: RatingBarIndicator(
                    rating: rating,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ToggleButtons(
                        isSelected: _selectedToggle,
                        onPressed: _onTogglePressed,
                        borderRadius: BorderRadius.circular(10),
                        selectedBorderColor: Colors.grey,
                        selectedColor: Colors.white,
                        fillColor: Palette.primaryColor,
                        color: Colors.black,
                        constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
                        children: _toggleText.map((text) => Text(text)).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Conditionally show Profile, Passports, Visas, or Pie Chart
                if (_showProfile && courierProfile != null)
                  BasicInfo(courierProfileData: courierProfile!),
                if (_showPassports)
                  Passports(passports: passports),
                if (_showVisas)
                  Visas(visas: visas),
                if (_showPieChart)
                  SizedBox(
                    child: Center(
                      child: CircularRating(
                        dataMap: dataMap,
                        colorList: colorList,
                        showLegendAtBottom: true, // 👈 Just set this where needed
                      ),
                    ),
                  ),

              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea( // ✅ Prevents overlap with system UI
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubmissionScreen(
                            brokerKey: AuthUtils.getCurrentUserId2().toString(),
                            courierKey: widget.courierKey,
                            onSave: (Task) {},
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.secondaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text('Place the Job'),
                  ),
                ),
              ),
            ),
          ),
          // Floating Action Button Positioned Above
          Positioned(
            bottom: 70, // Position it above the "Place the Job" button
            right: 20, // Adjust to align with the screen edge
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatDetailScreen(userID: widget.courierKey),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              child: Icon(Icons.chat, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
