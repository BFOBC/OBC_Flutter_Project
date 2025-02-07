import 'dart:math';
import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/broker/CircularRating.dart';
import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String name = '';
  String email = '';
  String contact = '';
  String address = '';
  String website = '';
  String imageUrl = '';
  String company = '';
  double brokerRating = 0.0;
  bool isLoading = true;

  bool _showProfile = true;
  bool _showPieChart = false;

  final Map<String, double> dataMap = {
    "Negative": 40,
    "Positive": 30,
    "Neutral": 30,
  };
  // Define the color list to match chart segments, tabs, and vertical bars
  final List<Color> _colorList = [
    Colors.orange, // In Progress
    Colors.red,    // Todo
    Colors.lightGreen,    // Pending
    Colors.green,  // Completed
  ];


  final List<bool> _selectedToggle = [true, false];
  final List<String> _toggleText = ['Basic Info', 'Rating'];
  List<BrokerProfileData> brokerInfoList = [];

  @override
  void initState() {
    super.initState();
    _fetchBrokerDetails();
  }

  void _fetchBrokerDetails() async {
    try {
      FirestoreService service = FirestoreService(context);
      List<BrokerProfileData> brokers = await service.fetchBrokerProfile(widget.brokerID); // Assuming brokerIDs is defined

      print('Broker Profile');
      print(brokers.length);
      setState(() {
        brokerInfoList = brokers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broker Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: brokerInfoList.map((brokerInfo) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_showProfile) ...[
                        // Broker Profile Picture
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: brokerInfo.profilePictureUrl != null &&
                              brokerInfo.profilePictureUrl != 'N/A'
                              ? NetworkImage(brokerInfo.profilePictureUrl!)
                              : null,
                          child: (brokerInfo.profilePictureUrl == null ||
                              brokerInfo.profilePictureUrl == 'N/A')
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Show Pie Chart only if _showPieChart and _showProfile are both true
                      if (_showPieChart && _showProfile)
                        CircularRating(
                          dataMap: dataMap,
                          colorList: _colorList,
                        ),

                      const SizedBox(height: 10),

                      // Broker Basic Information
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              brokerInfo.name ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Contact: ${brokerInfo.contact ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            RatingBarIndicator(
                              rating: brokerInfo.rating ?? 0,
                              itemBuilder: (context, index) =>
                              const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 25.0,
                              direction: Axis.horizontal,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Toggle Buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ToggleButtons(
                          isSelected: _selectedToggle,
                          onPressed: _onTogglePressed,
                          borderRadius: BorderRadius.circular(10),
                          selectedBorderColor: Colors.grey,
                          selectedColor: Colors.white,
                          fillColor: Colors.green,
                          color: Colors.black,
                          constraints: const BoxConstraints(
                              minHeight: 40.0, minWidth: 120.0),
                          children: _toggleText
                              .map((text) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(text),
                          ))
                              .toList(),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 30.0),
                        child: Divider(color: Colors.grey, thickness: 1.0),
                      ),

                      // Broker Profile Details
                      if (_showProfile)
                        BrokerBasicInfo(
                          name: brokerInfo.name,
                          email: brokerInfo.email ?? 'N/A',
                          phone: brokerInfo.contact ?? 'N/A',
                          website: brokerInfo.website ?? 'N/A',
                          company: brokerInfo.company ?? 'N/A',
                        ),

                      // Ratings Section
                      if (_showPieChart)
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            if (brokerInfo.ratings != null &&
                                brokerInfo.ratings!.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: brokerInfo.ratings!.length,
                                itemBuilder: (context, index) {
                                  var ratingItem = brokerInfo.ratings![index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 15),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ratingItem.from ?? "Anonymous",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          RatingBarIndicator(
                                            rating:
                                            ratingItem.rating?.toDouble() ?? 0.0,
                                            itemBuilder: (context, index) =>
                                            const Icon(Icons.star,
                                                color: Colors.amber),
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
                                                color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              const Text(
                                "No rating available",
                                style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 200,
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
