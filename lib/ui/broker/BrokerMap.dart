import 'dart:math';
import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/broker/SearchCourier.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/common/widgets/RadarAnimation.dart';
import 'package:broker_flutter_pp/ui/common/widgets/UserAvatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  double getCircleRadiusFromZoom(double zoom) {
    // You can tweak these values depending on visual testing
    if (zoom >= 18) return 100;     // very zoomed in
    if (zoom >= 16) return 300;
    if (zoom >= 14) return 500;
    if (zoom >= 12) return 800;
    if (zoom >= 10) return 1500;
    if (zoom >= 8) return 3000;      // your current zoom level
    if (zoom >= 6) return 5000;
    return 8000;                     // very zoomed out
  }
  Future<void> animateCamera(LatLng targetLocation, double zoomLevel) async {
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
      animateCamera(searchLocation, 8.0);

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
            'phoneNumber': (data.containsKey('countryCode') && data.containsKey('phoneNumber'))
                ? '${data['countryCode'] ?? ''}${data['phoneNumber'] ?? ''}'
                : 'N/A',
            'distance': distance,
            'searchCode': searchCode,
            'profilePictureUrl': data.containsKey('profilePictureUrl') ? data['profilePictureUrl'] ?? 'N/A' : 'N/A',
          });

        } catch (e) {
          print('❌ Error processing courier ${doc.id}: $e');
        }
      }

      animateCamera(searchLocation, 5.0);
// Add marker for searched location
      BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(24, 24)),
        'assets/place_holder_man.png',
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
              radius: 200000,
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
              radius: 200000,
              fillColor: Colors.red.withOpacity(0.1), // subtle glow
              strokeColor: Colors.red.withOpacity(0.6),
              strokeWidth: 4, // thicker border
            ),
          );

        });

      }
      setState(() {
        _isAnimatingRadar = false;
      });
      if (courierData.isEmpty) {
        print('❌ No nearby couriers found.');
        // 🛑 Optionally show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No couriers found at $searchCode'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        print('✅ Found ${courierData.length} couriers.');
/*        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${courierData.length} Courier(s) found at $searchCode'),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                showCouriersBottomSheet(context, courierData); // 👈 open sheet on tap
              },
            ),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );*/
        Fluttertoast.showToast(
          msg: '${courierData.length} Courier(s) found at $searchCode',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP, // 👈 show at top
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        showCouriersBottomSheet(context, courierData); // 👈 open sheet on tap

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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: couriers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final courier = couriers[index];
                              final profilePictureUrl = courier['profilePictureUrl']?.toString().trim();
                              final hasProfileImage = profilePictureUrl != null && profilePictureUrl.isNotEmpty;

                              // Log the profile picture URL
                              print("Courier [${courier['name'] ?? 'No Name'}] - Profile URL: $profilePictureUrl");

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
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Profile Picture or Icon
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Blue circular background
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          UserAvatar(imageUrl: courier['profilePictureUrl']),
                                        ],
                                      ),


                                      const SizedBox(width: 8),

                                      // Info Section
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              courier['name'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text(
                                                  courier['phoneNumber'] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.place, size: 16, color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${courier['distance']?.toStringAsFixed(2) ?? '0.00'} km away',
                                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Icon(Icons.chevron_right, color: Colors.grey),
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
            target: LatLng(51.1657, 10.4515),
            zoom: 2.0,
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
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3), // Limit to 3 characters
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')), // Allow only letters
                    ],
                    decoration: const InputDecoration(
                      hintText: '3 Letter Airport Code',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      if (value.length == 3) {
                        searchNearbyLocations(value.toUpperCase()); // ✅ call function
                      } else {
                        print('❌ Must be exactly 3 letters');
                      }
                    },
                  ),
                ),

                /// 👉 Added Search Button
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    final value = _searchController.text.trim();
                    if (value.length == 3) {
                      searchNearbyLocations(value.toUpperCase());
                    } else {
                      print('❌ Must be exactly 3 letters');
                    }
                  },
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

}
