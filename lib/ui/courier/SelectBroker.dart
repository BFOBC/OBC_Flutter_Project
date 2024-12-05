import 'dart:math';
import 'package:broker_flutter_pp/ui/broker/CircularRating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'BrokerBasicInfo.dart';
import 'JobDetails.dart';

class SelectBroker extends StatefulWidget {
  final String brokerID;

  const SelectBroker({Key? key, required this.brokerID}) : super(key: key);

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

  final List<Color> colorList = [
    Colors.red,
    Colors.green,
    Colors.blue,
  ];

  final List<bool> _selectedToggle = [true, false];
  final List<String> _toggleText = ['Basic Info', 'Rating'];
  List<Map<String, dynamic>> brokerInfoList = [];

  @override
  void initState() {
    super.initState();
    fetchBrokerDetails();
  }

  Future<void> fetchBrokerDetails() async {
  try {
    // Fetch all broker documents from Firestore
    QuerySnapshot brokerDocsSnapshot = await FirebaseFirestore.instance
        .collection('broker')
        .get();

    if (brokerDocsSnapshot.docs.isNotEmpty) {
      setState(() {
        // Create a list of broker data
        brokerInfoList = brokerDocsSnapshot.docs.map((doc) {
          return {
            'name': doc['name'] ?? 'N/A', // Handle null for name
            'contact': doc['contact'] ?? 'N/A', // Handle null for contact
            'imageUrl': doc['imageUrl'] ?? 'N/A', // Handle null for image
            'rating': 4.0, // Handle rating as double
            'email': doc['email'] ?? 'N/A', // Handle null for email
            'address': doc['address'] ?? 'N/A', // Handle null for address
            'website': doc['website'] ?? 'N/A', // Handle null for website
            'company': doc['company'] ?? 'N/A', // Handle null for website
          };
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        // If no brokers are found
        brokerInfoList = [{'name': 'N/A', 'contact': 'N/A', 'imageUrl': 'N/A', 'rating': 4.0}];
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      brokerInfoList = [{'name': 'Error fetching data', 'contact': 'N/A', 'image': 'N/A', 'rating': 4.0}];
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
    appBar: AppBar(
      title: Text('Broker Details'),
    ),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
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
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: brokerInfo['imageUrl'] != null &&
                                    brokerInfo['imageUrl'] != 'N/A'
                                ? NetworkImage(brokerInfo['imageUrl']!)
                                : null, // Fallback for missing or null imageUrl
                            child: brokerInfo['imageUrl'] == null ||
                                    brokerInfo['imageUrl'] == 'N/A'
                                ? Icon(Icons.person, size: 50) // Default icon
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Broker Name: ${brokerInfo['name'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Contact: ${brokerInfo['contact'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                RatingBarIndicator(
                                  rating: brokerInfo['rating'] ?? 0.0,
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
                              children:
                                  _toggleText.map((text) => Text(text)).toList(),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 30.0),
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1.0,
                            ),
                          ),
                          if (_showProfile)
                            BrokerBasicInfo(
                              name: brokerInfo['name'] ?? 'N/A',
                              email: brokerInfo['email'] ?? 'N/A',
                              phone: brokerInfo['contact'] ?? 'N/A',
                              address: brokerInfo['address'] ?? 'N/A',
                              website: brokerInfo['website'] ?? 'N/A',
                              company: brokerInfo['company'] ?? 'N/A',
                            ),
                        ],
                      ),
                    );
                  }).toList(),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const JobDetails()),
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
