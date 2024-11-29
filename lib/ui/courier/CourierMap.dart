import 'dart:math';
import 'package:broker_flutter_pp/ui/courier/emptyleg/CardStackWidget.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/EmptyLegMainScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../broker/SearchCourier.dart';


class CourierMap extends StatefulWidget {
  final String title;

  const CourierMap({super.key, required this.title});

  @override
  _OpenStreetMapScreenState createState() => _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState extends State<CourierMap> with SingleTickerProviderStateMixin {
  final bool _isSearching = false; // Radar animation state
  final bool _showMarkers = false; // Controls marker display after radar animation
  final List<Marker> _markers = []; // List of markers
  List<Map<String, dynamic>> emptyLegRequests = [];
bool isLoading = true;


  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    fetchEmptyLegRequests();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _radarAnimation = Tween<double>(begin: 0, end: 300).animate(_radarController)
      ..addListener(() {
        setState(() {});
      });
  }

  Future<void> fetchEmptyLegRequests() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('emptyLegRequests')
        .get();

    setState(() {
      emptyLegRequests = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'brokerID': data['brokerID'] ?? '',
          'courierID': data['courierID'] ?? '',
          'nodeID': data['nodeID'] ?? '',
          'requestDateTime': data['requestDateTime'] ?? '',
          'status': data['status'] ?? false,
        };
      }).toList();
      isLoading = false;
    });
  } catch (e) {
    print("Error fetching data: $e");
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  // Handle search input and trigger radar animation and markers
  /*void _onSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
        _showMarkers = false;
      });

      // Trigger radar animation, then show markers
      _radarController.forward().then((_) {
        setState(() {
          _isSearching = false;
          _showMarkers = true;
          _markers = _generateMockMarkers(); // Generate mock markers after search
        });
      });
    } else {
      setState(() {
        _showMarkers = false;
        _isSearching = false;
      });
    }
  }*/

  // Radar animation widget
  Widget _buildRadarAnimation() {
    return Center(
      child: CustomPaint(
        painter: RadarPainter(_radarAnimation.value),
        child: const SizedBox(
          width: 300,
          height: 300,
        ),
      ),
    );
  }

  /*// Generate mock markers with random locations and data
  List<Marker> _generateMockMarkers() {
    List<Marker> mockMarkers = [];
    for (int i = 0; i < 4; i++) {
      final lat = 30.3753 + Random().nextDouble() * 2; // Random nearby locations
      final lng = 69.3451 + Random().nextDouble() * 2;
      final marker = Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(lat, lng),
        builder: (ctx) => GestureDetector(
          onTap: () {
            // Navigate to SearchCourier screen with mock data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchCourier(
                  userName: 'User ${i + 1}',
                  rating: Random().nextDouble() * 5,
                  userImage: 'https://via.placeholder.com/150', // Placeholder image
                ),
              ),
            );
          },
          child: Image.asset('assets/map_icon.png'), // Custom marker icon from assets
        ),
      );
      mockMarkers.add(marker);
    }
    return mockMarkers;
  }*/

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Widget
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(30.3753, 69.3451), // Initial map center
            initialZoom: 5.0, // Initial zoom level
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            if (_showMarkers) MarkerLayer(markers: _markers), // Show markers after search
          ],
        ),

        // Input Field Positioned at the Top
        Positioned(
          top: 40.0,
          left: 20.0,
          right: 20.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 10.0),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Location',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Radar animation during search
        if (_isSearching)
          Positioned.fill(
            child: _buildRadarAnimation(),
          ),

          // Cards at the bottom of the screen
if (!isLoading && emptyLegRequests.isNotEmpty)
  Positioned(
    bottom: 20.0,
    left: 0,
    right: 0,
    child: CardStackWidget(
      flightDetailsList: emptyLegRequests.map((data) {
        return FlightDetails(
          userName: data['userName'],
          rating: data['rating'],
          fromLocation: data['fromLocation'],
          toLocation: data['toLocation'],
          fromDateTime: data['fromDateTime'],
          toDateTime: data['toDateTime'],
          flightNumber: data['flightNumber'],
          capacity: data['capacity'],
        );
      }).toList(),
    ),
  ),

      ],
    );
  }
}

// Custom painter to draw the radar effect
class RadarPainter extends CustomPainter {
  final double radius;

  RadarPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw the radar circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}