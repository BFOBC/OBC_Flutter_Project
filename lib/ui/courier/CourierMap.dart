import 'dart:async';
import 'dart:math';

import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/courier/SelectBroker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/DatabaseOperation.dart';
import '../common/models/AirportModel.dart';
import '../common/widgets/ConfirmLocationChangeDialog.dart';

class CourierMap extends StatefulWidget {
  final String title;

  const CourierMap({super.key, required this.title});

  @override
  _CourierMapState createState() => _CourierMapState();
}

class _CourierMapState extends State<CourierMap>
    with SingleTickerProviderStateMixin {
  List<Widget> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isSearchBarVisible = false; // Visibility state for search bar
  bool _isBaseSelected = false;
  String _searchText = ""; // This holds the text in the search bar
  String brokerName = '';
  String brokerContact = '';
  String country = '';
  String currentLocation = '';
  bool _isLoading = true;

  // Add a MapController to control the map
  Completer<GoogleMapController> _mapController = Completer();

  LatLng _baseLocation = const LatLng(0, 0); // Example: New York City
  LatLng _currentLocation = const LatLng(0, 0); // Example: Los Angeles
  late LatLng _selectedLocation; // Will store the currently selected location
  List<Map<String, dynamic>> brokerInfoList = [];

  List<AirportModel> airportList = [];
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  late User _currentUser;
  bool _hasData = false;

  List<String> _suggestedCountries = [];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    // getCurrentLocation(context);
    checkAndAnimateUserLocation(_currentUser.uid);
    fetchEmptyLegRequests();
  }

  // 🔹 Step 1: Location permission check
// 🔹 Step 1: Location permission check
// 🔹 Step 1: Permission check (as you already have)
  Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog(
        context,
        title: "Location Service Disabled",
        message:
        "⚠️ Please enable Location services in your phone settings to use this app.",
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDialog(
          context,
          title: "Permission Required",
          message:
          "❌ This app cannot work without location access.\n\nPlease allow location permission.",
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationDialog(
        context,
        title: "Permission Permanently Denied",
        message:
        "❗ Location permission is permanently denied.\n\nPlease open settings and enable permission for this app.",
        openSettings: true,
      );
      return false;
    }

    return true;
  }

// 🔹 Step 2: Get phone GPS location safely
  Future<LatLng> _getPhoneLocation() async {
    try {
      // ⏳ Timeout set to 10 sec max
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("⚠️ Location error: $e");
      // fallback: last known position
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return LatLng(lastPosition.latitude, lastPosition.longitude);
      }
      // agar kuch bhi na mila to default lat/lng (0,0)
      return const LatLng(0, 0);
    }
  }

// 🔹 Step 2: Custom Dialog
  void _showLocationDialog(
      BuildContext context, {
        required String title,
        required String message,
        bool openSettings = false,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false, // user tap/back se dismiss na kar sake
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            if (openSettings)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openAppSettings();
                },
                child: const Text(
                  "Open Settings",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }


  // 🔹 Step 3: Store location in Firestore
  Future<void> _saveLocationToFirestore(String uid, LatLng location) async {
    await FirebaseFirestore.instance.collection('courier').doc(uid).set({
      "currentLocationLat": location.latitude,
      "currentLocationLong": location.longitude,
    }, SetOptions(merge: true));
  }

  // 🔹 Step 4: Main method (decides Base vs Current)
  Future<void> checkAndAnimateUserLocation(String uid) async {
    try {
      if (!await _handleLocationPermission(context)) return;

      // Get saved location (base or current) from Firestore
      final doc =
          await FirebaseFirestore.instance.collection('courier').doc(uid).get();

      LatLng? finalLocation;

      if (doc.exists) {
        final data = doc.data()!;
        bool isBase = data['base'] ?? false;
        double lat = (data['baseLocationLat'] ?? 0).toDouble();
        double long = (data['baseLocationLong'] ?? 0).toDouble();
        _baseLocation = LatLng(lat, long);
        _isBaseSelected = true;
        if (isBase && lat != 0.0 && long != 0.0) {
          // ✅ Animate to Base Location
          finalLocation = LatLng(lat, long);
          _showSnack('📍 You are available at your base location.');
        }
      }

      // ❌ If base is not valid → fallback to current phone GPS
      if (finalLocation == null) {
        _isBaseSelected = false;
        finalLocation = await _getPhoneLocation();
        await _saveLocationToFirestore(uid, finalLocation);
        _showSnack('📍 You are available at your current location.');
      }

      // 🔹 Animate Google Map Camera
      animateCamera(finalLocation, 500.0);
    } catch (e) {
      _showSnack('🚫 Error fetching location: $e');
    }
  }

  Future<Position?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Step 1: Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Location services are disabled.')),
      );
      return null;
    }

    // Step 2: Check current permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('❌ Location permission denied by user.')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '❗ Location permission permanently denied. Open settings.')),
      );
      await Geolocator.openAppSettings();
      return null;
    }

    // Step 3: Try to get location from Firestore
    try {
      FirestoreService firsBase = FirestoreService(context);
      Map<String, double> location =
          await firsBase.getCourierLocation(_currentUser.uid);

      LatLng? finalLocation;

      if (location.isNotEmpty &&
          location['lat'] != null &&
          location['long'] != null &&
          (location['lat'] != 0.0 && location['long'] != 0.0)) {
        // ✅ Valid Firestore location
        finalLocation = LatLng(location['lat']!, location['long']!);
      } else {
        // ❌ Firestore location invalid → fallback to phone GPS
        Position gpsPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        finalLocation = LatLng(gpsPosition.latitude, gpsPosition.longitude);
      }

      _currentLocation = finalLocation;

      // Animate camera to chosen location
      animateCamera(finalLocation, 500.0);

      // Fetch courier location status
      final status = await firsBase.getCourierLocationStatus(_currentUser.uid);

      if (status != null) {
        String locationType = status.isCurrent ? "current" : "base";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are available at your $locationType location in ${status.country}.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch courier location status.'),
          ),
        );
      }

      return Position(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        // ✅ required
        headingAccuracy: 0.0, // ✅ required
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚫 Error fetching location: $e')),
      );
      return null;
    }
  }

  Future<void> fetchEmptyLegRequests() async {
    setState(() {
      _isLoading = true;
    });

    print("📡 fetchEmptyLegRequests: Started fetching...");

    FirestoreService firestoreService = FirestoreService(context);

    List<Map<String, dynamic>> requests = [];

    try {
      requests = await firestoreService
          .getEmptyLegRequestsWithBrokers(_currentUser.uid);
      print("✅ fetchEmptyLegRequests: Received ${requests.length} requests");

      for (var i = 0; i < requests.length; i++) {
        debugPrint("📦 Request[$i]: ${requests[i]}");
      }
    } catch (e) {
      print("❌ Error fetching empty leg requests: $e");
    }

    setState(() {
      _isLoading = false;
      if (requests.isNotEmpty) {
        _filteredUsers = _buildBottomSheetList(context, requests);
        _hasData = true; // ✅ data available
        print("📋 _filteredUsers updated, showing bottom sheet");
      } else {
        _hasData = false; // ❌ no data
        print("🚫 No requests found, hiding bottom sheet");
      }
    });
  }

  @override
  void dispose() {
    // _radarController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMarkerTap(bool isShown) {
    setState(() {
      _isSearchBarVisible =
          isShown; // Show the search bar when marker is tapped
    });
  }

  void showChangeBaseLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Tap outside to dismiss = false
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: EdgeInsets.only(top: 20, left: 24, right: 24),
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          actionsPadding: EdgeInsets.only(bottom: 10, right: 10),
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Change Base Location",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Do you want to change your base location?",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _onMarkerTap(false);
              },
              child: Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Background color
                foregroundColor: Colors.white, // Text (and icon) color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Your onPressed code here
                print("Base Location Marker tapped!");
                _onMarkerTap(true);
                Navigator.of(context).pop();
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void _onSearchAirport(String query) async {

    setState(() {
      _searchText = query; // Update the search text
      _isSearching = true; // Show loading state
    });

    try {
      // Fetch airports based on query
      airportList = await _fetchAirports(query);
      print("Fetched airports: $airportList");

      setState(() {
        _isSearching = false; // Hide loading state
        // Handle null values for iataCode
        _suggestedCountries = airportList
            .map((airport) =>
                airport.iataCode ?? 'Unknown') // Default value for null
            .where(
                (iataCode) => iataCode.isNotEmpty) // Filter out empty strings
            .toList();

        print(
            "Mapped IATA codes: ${airportList.map((airport) => airport.iataCode).toList()}");
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print("Error _onSearchAirport: $e");
    }
  }

// Function to fetch airports based on query
  Future<List<AirportModel>> _fetchAirports(String query) async {
    final dbHelper = DatabaseOperation();
    try {
      // Fetch the list of airports matching the GPS code
      List<AirportModel> airports =
          await dbHelper.fetchAirportsFromDatabase(query);
      return airports; // Return the fetched airports
    } catch (e) {
      print('Error _fetchAirports $e');
      return []; // Return an empty list in case of error
    }
  }

// Generate a random unique markerId
  String generateUniqueMarkerId() {
    final random = Random();
    return 'marker_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(10000)}';
  }

  void _onBaseLocationSelected(AirportModel airportItem) {
    try {
      // Extract lat and long
      double lat = double.tryParse(airportItem.lat.toString()) ?? 0.0;
      double long = double.tryParse(airportItem.long.toString()) ?? 0.0;
      LatLng latLng = LatLng(lat, long);

      // Create a unique markerId
      String markerId = generateUniqueMarkerId();

      // Update the markers set with a new marker
      setState(() {
        if (_isBaseSelected) {
          print('BaseLocationCountry $country');
          //for the time being to get the country name
          country = airportItem.countryCode.toString();
        }
        _baseLocation = latLng; // Update the selected location
        _markers = {
          Marker(
            markerId: MarkerId(markerId),
            position: _baseLocation,
            icon: BitmapDescriptor.defaultMarker,
            onTap: () {
              // Use Future.delayed to ensure Toast shows after UI updates
            },
          ),
        };

        // Animate the camera to the new location
        animateCamera(_baseLocation, 500.0);
        Future.delayed(Duration(milliseconds: 200), () {
          Fluttertoast.showToast(
            msg:
                "You are available at (${airportItem.country}, ${airportItem.city})",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        });

        // Reset other UI elements
        _searchText = "";
        _suggestedCountries = [];
        airportList = [];
      });

      // Call Firebase to update the base location asynchronously
      _updateBaseLocation(lat, long, true);
    } catch (e, stackTrace) {
      print("Error in _onBaseLocationSelected: $e");
      print(stackTrace);
    }
  }

  void _onCountrySelected(AirportModel airportItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmLocationChangeDialog(
          onConfirm: () {
            try {
              // Extract lat and long
              double lat = double.tryParse(airportItem.lat.toString()) ?? 0.0;
              double long = double.tryParse(airportItem.long.toString()) ?? 0.0;
              LatLng latLng = LatLng(lat, long);

              // Create a unique markerId
              String markerId = generateUniqueMarkerId();

              // Update the markers set with a new marker
              setState(() {
                if (_isBaseSelected) {
                  country = airportItem.countryCode.toString();
                }
                _baseLocation = latLng; // Update the selected location
                _markers = {
                  // Create a new Set with a single marker
                  Marker(
                    markerId: MarkerId(markerId),
                    // Unique identifier for the marker
                    position: _baseLocation,
                    icon: BitmapDescriptor.defaultMarker,
                    onTap: () {
                      // Use Future.delayed to ensure Snackbar is shown after UI updates
                      Future.delayed(Duration(milliseconds: 100), () {
                        print('Marker tapped!');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You are available at (${airportItem.country}, ${airportItem.city})',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      });
                    },
                  ),
                };

                // Animate the camera to the new location
                animateCamera(_baseLocation, 500.0);

                // Reset other UI elements
                _searchText = "";
                _suggestedCountries = [];
                airportList = [];
              });

              // Call Firebase to update the base location asynchronously
              _updateBaseLocation(lat, long, true);
            } catch (e, stackTrace) {
              print("Error in onConfirm: $e");
              print(stackTrace);
            }
          },
        );
      },
    );
  }

  void animateCamera(LatLng location, double zoom) async {
    final GoogleMapController controller = await _mapController.future;

    // ✅ Move camera close to the location
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 11.5), // 👈 try zoom = 16.0
      ),
    );

    // Marker & Circle
    Marker newMarker;
    Circle circle;

    if (_isBaseSelected) {
      newMarker = Marker(
        markerId: MarkerId('base_location'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Base Location'),
        onTap: () {
          showChangeBaseLocationDialog(context);
        },
      );

      circle = Circle(
        circleId: CircleId('base_circle'),
        center: location,
        radius: 300,
        // 👈 1000 meters = 1km radius
        fillColor: Colors.green.withOpacity(0.2),
        strokeColor: Colors.green,
        strokeWidth: 2,
      );
    } else {
      newMarker = Marker(
        markerId: MarkerId('current_location'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: 'Current Location'),
      );

      circle = Circle(
        circleId: CircleId('current_circle'),
        center: location,
        radius: 300,
        // 👈 Increase radius here too
        fillColor: Colors.red.withOpacity(0.15),
        strokeColor: Colors.red.withOpacity(0.5),
        strokeWidth: 2,
      );
    }

    setState(() {
      _markers.clear();
      _markers.add(newMarker);

      _circles.clear();
      _circles.add(circle);
    });
  }

  Future<String?> getCountryFromLatLng(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first.country;
      }
    } catch (e) {
      print('Error getting country: $e');
    }
    return null;
  }

  Future<void> _updateBaseLocation(
      double lat, double long, bool isLocationUpdate) async {
    final courierRef =
        FirebaseFirestore.instance.collection('courier').doc(_currentUser.uid);

    if(country.isEmpty){
      final db = DatabaseOperation();
      country= (await db.getCountryCodeByLatLong(lat, long))!; // Example lat/long
      print("Country Code Base Location: $country");

    }

    final data = isLocationUpdate
        ? {
            'baseLocationLat': lat,
            'baseLocationLong': long,
            'country': country,
            'base': true,
            'current': false,
          }
        : {
            'base': true,
            'current': false,
            'country': country,
          };

    try {
      await courierRef.set(data, SetOptions(merge: true));
      print("Base location updated successfully!");
    } catch (e) {
      print("Error updating base location: $e");
    }
  }

  Future<void> _updateCurrentLocation(double lat, double long) async {
    print("Updating current location...");
    print("Latitude: $lat");
    print("Longitude: $long");
    print("User ID: ${_currentUser.uid}");

    // Await the async method call
    String? country = await getCountryFromLatLng(lat, long);
    print("Country: $country");

    try {
      await FirebaseFirestore.instance
          .collection('courier')
          .doc(_currentUser.uid)
          .set({
        'currentLocationLat': lat,
        'currentLocationLong': long,
        'country': country ?? '',
        'base': false,
        'current': true,
      }, SetOptions(merge: true));

      print("Current location updated successfully!");
    } catch (e) {
      print("Error updating current location: $e");
    }
  }


// Permission check helper
  Future<bool> _checkLocationPermission(BuildContext context) async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    } else {
      var result = await Permission.location.request();
      if (result.isGranted) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is required!")),
        );
        return false;
      }
    }
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true, // 👈 Safe with keyboard & nav bar
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), // bottom safe padding
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Title
                    const Center(
                      child: Text(
                        'Change Availability',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Divider
                    Divider(thickness: 1.2, color: Colors.grey.shade300),
                    const SizedBox(height: 20),

                    // Toggle section
                    Row(
                      children: [
                        // Base option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBaseSelected = true;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isBaseSelected ? Colors.blue : Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                                border: Border.all(
                                  color: _isBaseSelected ? Colors.blue : Colors.grey.shade400,
                                ),
                                boxShadow: _isBaseSelected
                                    ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  'Base',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isBaseSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Current option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBaseSelected = false;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isBaseSelected ? Colors.blue : Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                border: Border.all(
                                  color: !_isBaseSelected ? Colors.blue : Colors.grey.shade400,
                                ),
                                boxShadow: !_isBaseSelected
                                    ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  'Current',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: !_isBaseSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Confirm button
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool hasPermission = await _checkLocationPermission(context);
                        if (!hasPermission) return; // agar permission nahi to exit

                        _selectedLocation = _isBaseSelected ? _baseLocation : _currentLocation;

                        if (_isBaseSelected) {
                          animateCamera(_baseLocation, 500.0);
                          _updateBaseLocation(
                            _baseLocation.latitude,
                            _baseLocation.longitude,
                            false,
                          );
                        } else {
                          if (!await _handleLocationPermission(context)) return;
                          _currentLocation= await _getPhoneLocation();
                          // thoda delay permission dene ke turant baad
                          await Future.delayed(const Duration(milliseconds: 300));
                          _currentLocation = await _getPhoneLocation();
                          animateCamera(_currentLocation, 500.0);
                          _updateCurrentLocation(
                            _currentLocation.latitude,
                            _currentLocation.longitude,
                          );
                        }

                        String message = _isBaseSelected
                            ? "You are available at Base Location"
                            : "You are available at Current Location";

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
                        );

                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(200, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.greenAccent,
                      ),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

// helper widget for toggle buttons
  Widget _buildOption({
    required bool isSelected,
    required String text,
    required bool isLeft,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey.shade100,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(10) : Radius.zero,
          right: !isLeft ? const Radius.circular(10) : Radius.zero,
        ),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade400,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
            : [],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  List<Widget> _buildBottomSheetList(
      BuildContext context, List<Map<String, dynamic>> brokerDataList) {
    final double containerWidth = MediaQuery.of(context).size.width;

    var list = <Widget>[];

    for (var brokerData in brokerDataList) {
      var brokerProfile = brokerData['broker'] ?? {};
      String userName = brokerProfile['name']?.toString() ?? 'Unknown Broker';
      String userImage = brokerProfile['profilePictureUrl']?.toString() ??
          'https://via.placeholder.com/150';
      String id = brokerProfile['brokerID']?.toString() ?? 'N/A';
      String nodeID =
          brokerData['emptyLegRequestID']?.toString() ?? 'nodeID Not Found';

      double rating = Random().nextDouble() * 5;

      list.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectBroker(
                  brokerID: id,
                  emptyLegRequestID: nodeID,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.all(16),
            width: containerWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(userImage),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 24.0,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // In the GoogleMap widget, pass _markers directly
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _baseLocation,
              zoom: 500.0,
            ),
            markers: _markers,
            // ✅ Already added
            circles: _circles,
            // ✅ 👈 Add this line here
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            onTap: (LatLng latLng) {
              print('Map Tap!');
            },
          ),

          // Conditionally show the progress bar
          if (_isLoading)
            Center(
              child:
                  CircularProgressIndicator(), // Progress indicator in the center
            ),

          // ✅ Search Bar with Done button
          if (_isSearchBarVisible)
            Positioned(
              top: 40.0,
              left: 16.0,
              right: 16.0,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            maxLength: 3,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z]')),
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Three Letter Airport Code',
                              counterText: "",
                              border: InputBorder.none,
                            ),
                            onSubmitted: (value) {
                              _onSearchAirport(value);
                            },
                          ),
                        ),

                        // ✅ Done Button (on right)
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () {
                            final value = _searchController.text.trim();
                            if (value.isNotEmpty) {
                              _onSearchAirport(value);
                            }
                          },
                        ),
                      ],
                    ),

                    // ✅ Search Result List
                    if (airportList.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: airportList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(airportList[index].name.toString()),
                            onTap: () {
                              _searchController.text="";
                              print("Clicked on: ${airportList[index].name}");
                              _onMarkerTap(false);
                              _onBaseLocationSelected(airportList[index]);
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),


          if (_hasData)
            DraggableScrollableSheet(
              initialChildSize: 0.5, // Sheet visible just a bit initially
              minChildSize: 0.2, // Minimum height (closed state)
              maxChildSize: 0.8, // Half screen height
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _filteredUsers[
                                index]; // Your custom card widgets
                          },
                        ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openBottomSheet,
        backgroundColor: Colors.red,
        child: const Icon(Icons.accessibility),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // 🔹 Utility Snack method
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
