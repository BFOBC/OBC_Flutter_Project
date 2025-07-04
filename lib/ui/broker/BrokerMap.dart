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
import 'dart:math' as Math;


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

  Set<Circle> _circles = {};
  late GoogleMapController _mapController; // Change to GoogleMapController
  final TextEditingController _searchController = TextEditingController();
  String courierKey = "";
  List<Map<String, dynamic>> courierData = []; // Now global, no _ prefix

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


  Set<String> _usedLocations = {}; // keep track of used lat+lng keys
/*  Future<void> searchNearbyLocations(String searchCode) async {
    print('🔍 Starting search for: $searchCode');

    if (searchCode.isEmpty) {
      print('⚠️ Search code is empty. Exiting search.');
      return;
    }

    setState(() {
      _isAnimatingRadar = true;
    });

    try {
      var searchedLocation = await _fetchAirports(searchCode);
      print('📡 Fetched airports: ${searchedLocation.length}');

      if (searchedLocation.isEmpty) {
        print('❌ No airport found for code: $searchCode');
        setState(() => _isAnimatingRadar = false);
        _markers.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No location found')));
        return;
      }

      final double searchedLat = double.tryParse(searchedLocation[0].lat.toString()) ?? 0.0;
      final double searchedLong = double.tryParse(searchedLocation[0].long.toString()) ?? 0.0;
      final LatLng searchLocation = LatLng(searchedLat, searchedLong);
      final String countryCode = searchedLocation[0].countryCode!;

      print('📍 Searched LatLng: $searchedLat, $searchedLong, Country: $countryCode');

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('courier')
          .where('country', isEqualTo: countryCode)
          .where('isOnline', isEqualTo: true)
          .get();

      print('🧾 Firebase docs fetched: ${snapshot.docs.length}');

      List<DocumentSnapshot> nearbyLocations = [];
      List<Marker> newMarkers = [];
      _usedLocations.clear();

      for (var doc in snapshot.docs) {
        try {
          bool isAtBase = doc['base'] ?? false;
          bool isAtCurrent = doc['current'] ?? false;

          double? docLat;
          double? docLong;

          if (isAtBase) {
            docLat = double.tryParse(doc['baseLocationLat']?.toString() ?? '');
            docLong = double.tryParse(doc['baseLocationLong']?.toString() ?? '');
          }

          if ((docLat == null || docLong == null) && isAtCurrent) {
            docLat = double.tryParse(doc['currentLocationLat']?.toString() ?? '');
            docLong = double.tryParse(doc['currentLocationLong']?.toString() ?? '');
          }

          // ✅ Skip if still invalid
          if (docLat == null || docLong == null) {
            print('⚠️ Skipping ${doc.id}: no valid base/current location.');
            continue;
          }

          // Avoid duplicates
// ✅ Avoid duplicate LatLng by applying small offset if needed
          final double validLat = docLat!;
          final double validLong = docLong!;
          String key = '${validLat.toStringAsFixed(6)}|${validLong.toStringAsFixed(6)}';
          int attempts = 0;

          double adjustedLat = validLat;
          double adjustedLong = validLong;

          int duplicateCount = 0;
          String baseKey = '${validLat.toStringAsFixed(6)}|${validLong.toStringAsFixed(6)}';

          while (_usedLocations.contains(baseKey) && duplicateCount < 10) {
            double angle = (duplicateCount + 1) * 30; // 30, 60, 90 degrees etc.
            double offset = 0.0001;

            double offsetLat = offset * Math.sin(angle * Math.pi / 180);
            double offsetLng = offset * Math.cos(angle * Math.pi / 180);

            adjustedLat = validLat + offsetLat;
            adjustedLong = validLong + offsetLng;

            baseKey = '${adjustedLat.toStringAsFixed(6)}|${adjustedLong.toStringAsFixed(6)}';
            duplicateCount++;
          }


// Update docLat/docLong with adjusted values
          docLat = adjustedLat;
          docLong = adjustedLong;



          double distance = calculateDistance(searchedLat, searchedLong, docLat!, docLong!);
          print('📏 Distance to searched for ${doc.id}: $distance');

          BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(24, 24)),
            'assets/map_icon.png',
          );
          final markerKey = '${doc.id}_${docLat}_$docLong';

          LatLng location = LatLng(docLat, docLong);
          newMarkers.add(Marker(
            markerId: MarkerId(markerKey),
            position: location,
            icon: customIcon,
            onTap: () => _onMarkerTapped(doc.id),
          ));
          nearbyLocations.add(doc);
        } catch (e) {
          print('❌ Error processing courier ${doc.id}: $e');
        }
      }

      setState(() {
        _isAnimatingRadar = false;
        _markers.clear();
        _markers.addAll(newMarkers);
        _showMarkers = nearbyLocations.isNotEmpty;
      });

      if (nearbyLocations.isEmpty) {
        print('❌ No nearby couriers found.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No Couriers found')));
      } else {
        print('✅ Found ${nearbyLocations.length} couriers.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${nearbyLocations.length} Courier(s) found at $searchCode')),
        );
      }

      Circle circle = Circle(
        circleId: CircleId('current_circle'),
        center: searchLocation,
        radius: 1000,
        fillColor: Colors.green.withOpacity(0.15),
        strokeColor: Colors.green.withOpacity(0.5),
        strokeWidth: 2,
      );

      setState(() {
        _circles.clear();
        _circles.add(circle);
      });

      animateCamera(searchLocation, 12.0);
    } catch (e, stackTrace) {
      print('❌ Exception in searchNearbyLocations: $e');
      print(stackTrace);

      setState(() => _isAnimatingRadar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred during search.')));
    }
  }*/
  Future<void> searchNearbyLocations(String searchCode) async {
    print('🔍 Starting search for: $searchCode');
    courierData.clear();

    if (searchCode.isEmpty) {
      print('⚠️ Search code is empty. Exiting search.');
      return;
    }

    setState(() {
      _isAnimatingRadar = true;
    });

    try {
      var searchedLocation = await _fetchAirports(searchCode);
      print('📡 Fetched airports: ${searchedLocation.length}');

      if (searchedLocation.isEmpty) {
        print('❌ No airport found for code: $searchCode');
        setState(() => _isAnimatingRadar = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No location found')));
        return;
      }

      final double searchedLat = double.tryParse(searchedLocation[0].lat.toString()) ?? 0.0;
      final double searchedLong = double.tryParse(searchedLocation[0].long.toString()) ?? 0.0;
      final LatLng searchLocation = LatLng(searchedLat, searchedLong);
      final String countryCode = searchedLocation[0].countryCode!;

      print('📍 Searched LatLng: $searchedLat, $searchedLong, Country: $countryCode');


      // Animate map to searched location
      animateCamera(searchLocation, 12.0);

      // Firestore fetch
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('courier')
          .where('country', isEqualTo: countryCode)
          .where('isOnline', isEqualTo: true)
          .get();

      print('🧾 Firebase docs fetched: ${snapshot.docs.length}');


      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          bool isAtBase = data.containsKey('base') ? data['base'] ?? false : false;
          bool isAtCurrent = data.containsKey('current') ? data['current'] ?? false : false;

          double? docLat, docLong;

          if (isAtBase) {
            docLat = double.tryParse(data['baseLocationLat']?.toString() ?? '');
            docLong = double.tryParse(data['baseLocationLong']?.toString() ?? '');
          }

          if ((docLat == null || docLong == null) && isAtCurrent) {
            docLat = double.tryParse(data['currentLocationLat']?.toString() ?? '');
            docLong = double.tryParse(data['currentLocationLong']?.toString() ?? '');
          }

          if (docLat == null || docLong == null) {
            print('⚠️ Skipping ${doc.id}: no valid base/current location.');
            continue;
          }

          double distance = calculateDistance(searchedLat, searchedLong, docLat, docLong);

          courierData.add({
            'key': doc.id, // 🔑 Firestore doc ID
            'name': data.containsKey('name') ? data['name'] ?? 'N/A' : 'N/A',
            'number': data.containsKey('number') ? data['number'] ?? 'N/A' : 'N/A',
            'distance': distance,
            'searchCode': searchCode,
          });
        } catch (e) {
          print('❌ Error processing courier ${doc.id}: $e');
        }
      }

      animateCamera(searchLocation, 14.0);
// Add marker for searched location
      BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(24, 24)),
        'assets/map_icon.png',
      );


// First clear any existing markers/circles
      setState(() {
        _markers.clear();
        _circles.clear();
      });

// ✅ If couriers found
      if (courierData.isNotEmpty) {
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId('searched_location'),
              position: searchLocation,
              icon: customIcon,
              onTap: () {
                showCouriersBottomSheet(context, courierData);
              },
            ),
          );

          _circles.add(
            Circle(
              circleId: CircleId('searched_circle'),
              center: searchLocation,
              radius: 1000,
              fillColor: Colors.green.withOpacity(0.1),
              strokeColor: Colors.green.shade700.withOpacity(0.6),
              strokeWidth: 4,
            ),
          );

        });
      } else {
        // ❌ No couriers → Just Red Circle
        setState(() {
          _circles.add(
            Circle(
              circleId: CircleId('no_courier_circle'),
              center: searchLocation,
              radius: 1000,
              fillColor: Colors.red.withOpacity(0.1), // subtle glow
              strokeColor: Colors.red.withOpacity(0.6),
              strokeWidth: 4, // thicker border
            ),
          );

        });

        // 🛑 Optionally show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No couriers found at $searchCode')),
        );
      }



      setState(() {
        _isAnimatingRadar = false;
      });

      if (courierData.isEmpty) {
        print('❌ No nearby couriers found.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No Couriers found')));
      } else {
        print('✅ Found ${courierData.length} couriers.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${courierData.length} Courier(s) found at $searchCode')),
        );

        showCouriersBottomSheet(context, courierData);
      }
    } catch (e, stackTrace) {
      print('❌ Exception in searchNearbyLocations: $e');
      print(stackTrace);
      setState(() => _isAnimatingRadar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred during search.')));
    }
  }
  void showCouriersBottomSheet(BuildContext context, List<Map<String, dynamic>> couriers) {
    if (couriers.isEmpty) return;

    final airportCode = couriers.first['searchCode'] ?? 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // 🔒 Disable tap outside to dismiss
      enableDrag: false, // 🔒 Disable full drag to dismiss
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: [0.3, 0.7, 0.9],
          expand: false,
          builder: (_, scrollController) {
            return WillPopScope(
              onWillPop: () async => false, // 🔒 Disable system back
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top bar + Close Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop(); // ✅ Manually close
                              },
                            ),
                          ],
                        ),
                      ),

                      // 🌐 Stylish Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flight_takeoff, color: Colors.blue, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Airport Code: $airportCode',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              '✈️ ${couriers.length} Courier${couriers.length > 1 ? 's' : ''} Found Nearby',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 16),
                            Divider(
                              thickness: 1.2,
                              color: Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),

                      // 🚚 Courier List
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: couriers.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final courier = couriers[index];

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final courierKey = courier['key'];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchCourier(courierKey: courierKey),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Avatar or Icon
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Icon(Icons.local_shipping, color: Colors.blue, size: 18),
                                    ),
                                    SizedBox(width: 16),

                                    // Info Section
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            courier['name'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                              SizedBox(width: 6),
                                              Text(
                                                courier['number'] ?? 'N/A',
                                                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.place, size: 16, color: Colors.grey[600]),
                                              SizedBox(width: 6),
                                              Text(
                                                '${courier['distance'].toStringAsFixed(2)} km away',
                                                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Arrow icon
                                    Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
          circles: _circles, // ✅ 👈 Add this line here
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
  void animateToFitAllMarkers(Set<Marker> markers) {
    if (markers.isEmpty) return;

    LatLngBounds bounds = _createBounds(markers.map((m) => m.position).toList());

    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwestLat = positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final southwestLng = positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final northeastLat = positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final northeastLng = positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    return LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );
  }

}
