import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/broker/CircularRating.dart';
import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:broker_flutter_pp/ui/common/models/Rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'BrokerBasicInfo.dart';
import 'JobDetails.dart';

class SelectBroker extends StatefulWidget {
  final String brokerID;
  final String emptyLegRequestID;

  const SelectBroker({super.key, required this.brokerID, required this.emptyLegRequestID});

  @override
  _SelectBrokerState createState() => _SelectBrokerState();
}

class _SelectBrokerState extends State<SelectBroker> {
  BrokerProfileData? brokerInfo;
  bool isLoading = true;

  bool _showProfile = true;
  bool _showPieChart = false;


  // Default rating distribution
  Map<String, double> dataMap = {
    "Negative": 0,
    "Positive": 0,
    "Neutral": 0,
  };

  final List<Color> _colorList = [Colors.orange, Colors.red, Colors.lightGreen, Colors.green];
  final List<bool> _selectedToggle = [true, false];
  final List<String> _toggleText = ['Basic Info', 'Rating'];

  @override
  void initState() {
    super.initState();

    _fetchBrokerDetails();

    if (brokerInfo?.ratings != null && brokerInfo!.ratings!.isNotEmpty) {
      int negativeCount = 0;
      int neutralCount = 0;
      int positiveCount = 0;

      // Categorize ratings
      for (var ratingItem in brokerInfo!.ratings!) {
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

  void _fetchBrokerDetails() async {
    try {
      FirestoreService service = FirestoreService(context);
      BrokerProfileData? broker = await service.fetchBrokerProfile2(widget.brokerID);

      if (broker != null) {
        setState(() {
          brokerInfo = broker;
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onTogglePressed(int index) {
    setState(() {
      for (int i = 0; i < _selectedToggle.length; i++) {
        _selectedToggle[i] = i == index;
      }
      _showProfile = index == 0;
      _showPieChart = index == 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broker Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : brokerInfo == null
          ? const Center(child: Text("Broker not found"))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fixed Header Section (Profile & Rating)
          const SizedBox(height: 10),
          CircleAvatar(
            radius: 50,
            backgroundImage: brokerInfo!.profilePictureUrl != null &&
                brokerInfo!.profilePictureUrl != 'N/A'
                ? NetworkImage(brokerInfo!.profilePictureUrl!)
                : null,
            child: brokerInfo!.profilePictureUrl == null ||
                brokerInfo!.profilePictureUrl == 'N/A'
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            brokerInfo!.name ?? 'N/A',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            'Contact: ${brokerInfo!.phoneNumber ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          RatingBarIndicator(
            rating: brokerInfo!.rating ?? 0,
            itemBuilder: (context, index) =>
            const Icon(Icons.star, color: Colors.amber),
            itemCount: 5,
            itemSize: 25.0,
            direction: Axis.horizontal,
          ),
          const SizedBox(height: 10),

          // Toggle Buttons for switching between tabs
          ToggleButtons(
            isSelected: _selectedToggle,
            onPressed: _onTogglePressed,
            borderRadius: BorderRadius.circular(10),
            selectedBorderColor: Colors.grey,
            selectedColor: Colors.white,
            fillColor: Colors.green,
            color: Colors.black,
            constraints:
            const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
            children: _toggleText
                .map((text) => Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(text),
            ))
                .toList(),
          ),

          const Divider(color: Colors.grey, thickness: 1.0),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_showProfile)
                    BrokerBasicInfo(
                      name: brokerInfo!.name,
                      email: brokerInfo!.email ?? 'N/A',
                      phone: brokerInfo!.phoneNumber ?? 'N/A',
                      website: brokerInfo!.website ?? 'N/A',
                      company: brokerInfo!.company ?? 'N/A',
                    ),

                  if (_showPieChart)
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      child: CircularRating(
                        dataMap: calculateRatingDistribution(
                            brokerInfo!.ratings ?? []),
                        colorList: _colorList,
                      ),
                    ),

                  if (_showPieChart) ...[
                    brokerInfo!.ratings != null &&
                        brokerInfo!.ratings!.isNotEmpty
                        ? ListView.builder(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount: brokerInfo!.ratings!.length,
                      itemBuilder: (context, index) {
                        var ratingItem =
                        brokerInfo!.ratings![index];
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                RatingBarIndicator(
                                  rating: ratingItem.rating
                                      ?.toDouble() ??
                                      0.0,
                                  itemBuilder: (context,
                                      index) =>
                                  const Icon(Icons.star,
                                      color:
                                      Colors.amber),
                                  itemCount: 5,
                                  itemSize: 20.0,
                                  direction: Axis.horizontal,
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
                        : const Text("No rating available",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Button placed in bottomNavigationBar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => JobDetails(
                      emptyLegRequestID: widget.emptyLegRequestID,
                      brokerID: widget.brokerID,
                    )),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:Colors.green,
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
    );
  }

}
