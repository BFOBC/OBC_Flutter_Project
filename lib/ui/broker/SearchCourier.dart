import 'dart:math';
import 'package:broker_flutter_pp/ui/broker/mission/PlaceNewJob.dart';
import 'package:broker_flutter_pp/ui/broker/requestscreens/Submission.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Rating.dart';
import 'package:broker_flutter_pp/ui/common/models/Visa.dart';
import 'package:broker_flutter_pp/ui/common/utils/AuthUtils.dart';
import 'package:broker_flutter_pp/ui/common/widgets/UserAvatar.dart';
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

  final List<Color> _colorList = [
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

    if (courierProfile?.ratings != null && courierProfile!.ratings!.isNotEmpty) {
      int negativeCount = 0;
      int neutralCount = 0;
      int positiveCount = 0;

      // Categorize ratings
      for (var ratingItem in courierProfile!.ratings!) {
        double rating = ratingItem.rating?.toDouble() ?? 0.0;

        if (rating < 3) {
          negativeCount++;
        } else if (rating >= 5 && rating < 8) {
          neutralCount++;
        } else if (rating >= 8) {
          positiveCount++;
        }
      }

      // Calculate percentages
      int total = negativeCount + neutralCount + positiveCount;
      if (total > 0) {
        dataMap["Negative"] = (negativeCount / total) * 100;
        dataMap["Neutral"] = (neutralCount / total) * 100;
        dataMap["Positive"] = (positiveCount / total) * 100;
      } else {
        // If no ratings, mark neutral by default
        dataMap["Neutral"] = 100;
      }
    } else {
      // If no ratings available, set 100% Neutral
      dataMap["Neutral"] = 100;
    }
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
          userImage = data['profilePictureUrl'] ?? 'N/A';  // Use 'N/A' if 'userImage' is null
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
          ? const Center(
        child: CircularProgressIndicator(), // Show progress bar while loading
      )
          : SafeArea(
        child: Column(
          children: [
            // 🔹 Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(imageUrl: userImage),

                    const SizedBox(height: 5),
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
                    const SizedBox(height: 5),

                    // 🔹 Toggle buttons
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
                            constraints: const BoxConstraints(
                                minHeight: 40.0, minWidth: 100.0),
                            children: _toggleText
                                .map((text) => Text(text))
                                .toList(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔹 Conditional sections
                    if (_showProfile && courierProfile != null)
                      BasicInfo(courierProfileData: courierProfile!),
                    if (_showPassports) Passports(passports: passports),
                    if (_showVisas) Visas(visas: visas),
                    if (_showPieChart)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: CircularRating(
                          dataMap: calculateRatingDistribution(
                              courierProfile!.ratings ?? []),
                          colorList: _colorList,
                        ),
                      ),

                    if (_showPieChart) ...[
                      courierProfile!.ratings != null &&
                          courierProfile!.ratings!.isNotEmpty
                          ? ListView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount:
                        courierProfile!.ratings!.length,
                        itemBuilder: (context, index) {
                          var ratingItem =
                          courierProfile!.ratings![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 15),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ratingItem.from ??
                                        "Anonymous",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                  RatingBarIndicator(
                                    rating: ratingItem.rating
                                        ?.toDouble() ??
                                        0.0,
                                    itemBuilder: (context, index) =>
                                    const Icon(Icons.star,
                                        color: Colors.amber),
                                    itemCount: 5,
                                    itemSize: 20.0,
                                    direction:
                                    Axis.horizontal,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    ratingItem.comment ??
                                        "No comment provided.",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                        Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                          : const Text(
                        "No rating available",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 🔹 Fixed bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  // Chat button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                                userID: widget.courierKey),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text("Chat", style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.primaryColor,
                        side: const BorderSide(color: Palette.primaryColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Place Job button
                  Expanded(
                    child: ElevatedButton.icon(
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
                      icon: const Icon(Icons.work_rounded, size: 18, color: Colors.white),
                      label: const Text("Place Job", style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Map<String, double> calculateRatingDistribution(List<Rating> ratings) {
    double negativeCount = 0;
    double neutralCount = 0;
    double positiveCount = 0;

    for (var ratingItem in ratings) {
      double ratingValue = ratingItem.rating?.toDouble() ?? 0.0;

      if (ratingValue < 3) {
        negativeCount++;
      } else if (ratingValue >= 5 && ratingValue < 8) {
        neutralCount++;
      } else if (ratingValue >= 8) {
        positiveCount++;
      }
    }

    // Handle case where no ratings match categories
    if (negativeCount == 0 && neutralCount == 0 && positiveCount == 0) {
      neutralCount = 1; // Default to 0 neutral if no ratings found
    }

    return {
      "Negative": negativeCount,
      "Neutral": neutralCount,
      "Positive": positiveCount,
    };
  }
}
