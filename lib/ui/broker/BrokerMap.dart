import 'dart:math';
import 'package:broker_flutter_pp/data/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/broker/SearchCourier.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/widgets/RadarAnimation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BrokerMap extends StatefulWidget {
  final String title;

  const BrokerMap({super.key, required this.title});

  @override
  _BrokerMapState createState() => _BrokerMapState();
}

class _BrokerMapState extends State<BrokerMap> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  bool _showMarkers = false;
  bool _isAnimatingRadar = false;

  List<Marker> _markers = [];

  final TextEditingController _searchController = TextEditingController();
  // Add a MapController to control the map
  late MapController _mapController;
  String courierKey="";

  @override
  void initState() {
    super.initState();
    _mapController = MapController();  // Initialize MapController
  }
  // Method to increase the zoom level
  void _zoomIn() {
    double currentZoom = _mapController.camera.zoom;
    if (currentZoom < 18) {
      _mapController.move(_mapController.camera.center, currentZoom + 1);
    }
  }

  // Method to decrease the zoom level
  void _zoomOut() {
    double currentZoom = _mapController.camera.zoom;
    if (currentZoom > 1) {
      _mapController.move(_mapController.camera.center, currentZoom - 1);
    }
  }

  // Fetch details of an airport by GPS code
  Future<Map<String, dynamic>?> fetchAirportDetail(String code) async {
    final dbHelper = DatabaseOperation();
    try {
      // Fetch the list of airports matching the GPS code
      List<Map<String, dynamic>> results = await dbHelper.fetchAirportsByGpsCode(code);

      // Return the first matching airport, or null if no match is found
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      print('Error fetching airport details: $e');
      return null;
    }
  }

  // Function to fetch airports based on query
  Future<List<AirportModel>> _fetchAirports(String query) async {
    final dbHelper = DatabaseOperation();
    try {
      // Fetch the list of airports matching the GPS code
      List<AirportModel> airports = await dbHelper.fetchAirportsFromDatabase(query);
      return airports; // Return the fetched airports
    } catch (e) {
      print('Error _fetchAirports $e');
      return []; // Return an empty list in case of error
    }
  }

  void _searchAirport(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 3-letter airport code.')),
      );
      return;
    }

    try {
      setState(() {
        _isSearching = true;
      });

      // Fetch airport details
      List<AirportModel> airportDetail  = await _fetchAirports(code);

      if (airportDetail.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Airport: ${airportDetail[0].name}, City: ${airportDetail[0].city}, Country: ${airportDetail[0].country}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No airport found for code: $code')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching airport details: $error')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Haversine formula to calculate the distance between two geo points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371; // Earth's radius in kilometers
    var dLat = _toRadians(lat2 - lat1);
    var dLon = _toRadians(lon2 - lon1);

    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radius * c; // distance in kilometers
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  Future<void> searchNearbyLocations(String searchCode) async {
    if (searchCode.isEmpty) {
      return; // Don't proceed if the searchCode is null or empty
    }

    setState(() {
      _isAnimatingRadar = true;  // Start the radar animation
    });

    // Example: Get location based on the search code (ISB in your case)
    var searchedLocation = await _fetchAirports(searchCode);

    if (searchedLocation.isEmpty) {
      setState(() {
        _isAnimatingRadar = false;  // Stop the radar if no location found
      });
      _markers.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No location model found')),
      );
      return;
    }

    // Ensure the lat and long values are parsed to double
    double searchedLat = double.tryParse(searchedLocation[0].lat.toString()) ?? 0.0;
    double searchedLong = double.tryParse(searchedLocation[0].long.toString()) ?? 0.0;
    LatLng searchLocation=LatLng(searchedLat, searchedLong);

    // Firestore query to get documents where 'country' is 'Pakistan' and the location code matches the search query
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('courier') // Your Firestore collection name
        .where('country', isEqualTo: searchedLocation[0].countryCode)  // Filter for country
        .get();

    print('Snapshot retrieved from Firestore:');
    print(snapshot.docs);  // This will print the list of documents

    List<DocumentSnapshot> nearbyLocations = [];

    // Loop through each document and calculate the distance
      _markers.clear();
    for (var doc in snapshot.docs) {
      print('Document ID: ${doc.id}');
      print('Document Data: ${doc.data()}'); // Print all fields in the document

      double docLat = double.tryParse(doc['baseLocationLat'].toString()) ?? 0.0;
      double docLong = double.tryParse(doc['baseLocationLong'].toString()) ?? 0.0;

      // Calculate distance
      double distance = calculateDistance(searchedLat, searchedLong, docLat, docLong);

     // if (distance <= 1.0) { // If the distance is within 1 kilometer
        nearbyLocations.add(doc);
      //}
      LatLng location=LatLng(docLat,docLong);
      Key courierKey=Key(doc.id);
      _markers = [
        Marker(
          key: courierKey,
          width: 100.0,
          height: 100.0,
          point: location,
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 80,
          ),
        ),
      ];
    }

   // _mapController.move(searchLocation, 8.0); // Animate to the new location
    // Stop the radar animation once the model is received
    setState(() {
      _isAnimatingRadar = false;
      if(nearbyLocations.isNotEmpty) {
        _showMarkers=true;
      }
    });

    // Show a snackbar if no nearby locations are found
    if (nearbyLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No records found')),
      );
    } else {
      print('Nearby Locations: ${nearbyLocations.length}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${nearbyLocations.length} Courier found at $searchCode')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Widget
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(30.3753, 69.3451),
            initialZoom: 5.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            if (_showMarkers)
/*              MarkerLayer(
                markers: _markers,
              ),*/
              MarkerLayer(
                markers: _markers.map((markerData) {
                  return Marker(
                    point: markerData.point,
                    width: 100.0,
                    height: 100.0,
                    // Marker child, here you can use any widget or icon as a marker
                    child: GestureDetector(
                      onTap: () {
                        // Handle marker click here
                        _onMarkerTapped(markerData.key.toString());
                      },
                      child: Image.asset(
                        'assets/map_icon.png', // Path to custom marker icon
                        width: 100.0,
                        height: 100.0,
                      ),
                    ),
                  );
                }).toList(),
              )

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
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10.0),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '3 Letter Airport Code',
                      border: InputBorder.none,
                    ),
                    onSubmitted: searchNearbyLocations,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Radar animation
        if (_isAnimatingRadar)
          Positioned.fill(
            child: RadarAnimation(isAnimating: _isAnimatingRadar),
          ),

        if (_isSearching)
          Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
  // Inside your map's marker click handler
  void _onMarkerTapped(String courierKey) {
    String cleanCourierKey = courierKey.replaceAll(RegExp(r'[\[\]<>]'), '').replaceAll("'", "");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchCourier(
          courierKey: cleanCourierKey, // Pass the courierKey here
        ),
      ),
    );
  }

}
class MarkerData {
  final LatLng point;
  final String courierKey;
  final String userName;
  final String userImage;
  final double rating;

  MarkerData({
    required this.point,
    required this.courierKey,
    required this.userName,
    required this.userImage,
    required this.rating,
  });
}
