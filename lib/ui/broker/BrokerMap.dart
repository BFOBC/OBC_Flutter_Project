import 'dart:math';
import 'package:broker_flutter_pp/data/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/broker/SearchCourier.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/common/widgets/RadarAnimation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart'; // Correct LatLng import


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
  late GoogleMapController _mapController; // Change to GoogleMapController
  final TextEditingController _searchController = TextEditingController();
  String courierKey = "";

  @override
  void initState() {
    super.initState();
  }


  void animateCamera(LatLng targetLocation, double zoomLevel) {
    CameraPosition cameraPosition = CameraPosition(target: targetLocation, zoom: zoomLevel);
    _mapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<Map<String, dynamic>?> fetchAirportDetail(String code) async {
    final dbHelper = DatabaseOperation();
    try {
      List<Map<String, dynamic>> results = await dbHelper.fetchAirportsByGpsCode(code);
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      print('Error fetching airport details: $e');
      return null;
    }
  }

  Future<List<AirportModel>> _fetchAirports(String query) async {
    final dbHelper = DatabaseOperation();
    try {
      List<AirportModel> airports = await dbHelper.fetchAirportsFromDatabase(query);
      return airports;
    } catch (e) {
      print('Error _fetchAirports $e');
      return [];
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

      List<AirportModel> airportDetail = await _fetchAirports(code);

      if (airportDetail.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Airport: ${airportDetail[0].name}, City: ${airportDetail[0].city}, Country: ${airportDetail[0].country}')),
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

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371; // Earth's radius in kilometers
    var dLat = _toRadians(lat2 - lat1);
    var dLon = _toRadians(lon2 - lon1);

    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

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
      _isAnimatingRadar = true;
    });

    var searchedLocation = await _fetchAirports(searchCode);

    if (searchedLocation.isEmpty) {
      setState(() {
        _isAnimatingRadar = false;
      });
      _markers.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No location found')));
      return;
    }

    double searchedLat = double.tryParse(searchedLocation[0].lat.toString()) ?? 0.0;
    double searchedLong = double.tryParse(searchedLocation[0].long.toString()) ?? 0.0;
    LatLng searchLocation = LatLng(searchedLat, searchedLong);

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('courier')
        .where('country', isEqualTo: searchedLocation[0].countryCode)
        .where('isOnline', isEqualTo: true)
        .get();

    List<DocumentSnapshot> nearbyLocations = [];
    _markers.clear();

    for (var doc in snapshot.docs) {
      double docLat = double.tryParse(doc['baseLocationLat'].toString()) ?? 0.0;
      double docLong = double.tryParse(doc['baseLocationLong'].toString()) ?? 0.0;

      double distance = calculateDistance(searchedLat, searchedLong, docLat, docLong);
      BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(24, 24)), // Adjust size if needed
        'assets/map_icon.png',
      );
      nearbyLocations.add(doc);
      LatLng location = LatLng(docLat, docLong);
      _markers.add(Marker(
        markerId: MarkerId(doc.id),
        position: location,
        icon: customIcon,  // Use your custom marker icon here
        onTap: () => _onMarkerTapped(doc.id),
      ));
    }

    setState(() {
      _isAnimatingRadar = false;
      if (nearbyLocations.isNotEmpty) {
        _showMarkers = true;
      }
    });

    if (nearbyLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No Couriers found')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nearbyLocations.length} Courier found at $searchCode')));
    }

    setState(() {
      animateCamera(searchLocation, 10.0);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(30.3753, 69.3451),
            zoom: 5.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller; // Initialize GoogleMapController
          },
          markers: Set<Marker>.of(_markers),
        ),

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

        if (_isAnimatingRadar)
          Positioned.fill(
            child: RadarAnimation(isAnimating: _isAnimatingRadar),
          ),

        if (_isSearching)
          Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  void _onMarkerTapped(String courierKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchCourier(courierKey: courierKey),
      ),
    );
  }
}
