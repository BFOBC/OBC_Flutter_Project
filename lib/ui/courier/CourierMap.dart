import 'dart:async';
import 'dart:math';

import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/courier/SelectBroker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:card_stack_widget/card_stack_widget.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  bool _showCardStack = false;
  List<Widget> _filteredUsers = [];

  bool _isSearching = false;
  bool _isSearchBarVisible = true; // Visibility state for search bar
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;
  bool _isBaseSelected = true;
  String _searchText = ""; // This holds the text in the search bar
  String brokerName = '';
  String brokerContact = '';
  String country = '';
  String currentLocation = '';
  bool _isLoading = true;

  // Add a MapController to control the map
  Completer<GoogleMapController> _mapController = Completer();

  //Location location = Location(); // Create a Location instance

  LatLng _baseLocation =
      const LatLng(30.3753, 69.3451); // Example: New York City
  LatLng _currentLocation =
      const LatLng(30.3753, 69.3451); // Example: Los Angeles
  late LatLng _selectedLocation; // Will store the currently selected location
  List<Map<String, dynamic>> brokerInfoList = [];

  List<AirportModel> airportList = [];
  Set<Marker> _markers = {};
  late User _currentUser;

  late Future<List<Map<String, dynamic>>> _brokerDataFuture;

  List<String> _suggestedCountries = [];

  @override
  void initState() {
    super.initState();
    _radarController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _radarAnimation =
        Tween<double>(begin: 0, end: 300).animate(_radarController)
          ..addListener(() {
            setState(() {});
          });
    _currentUser = FirebaseAuth.instance.currentUser!;
    getCurrentLocation(context);
    //_onSearch("abc");
    //fetchEmptyLegRequests();
    // FirestoreService firestoreService = FirestoreService(context);

    //_brokerDataFuture = firestoreService.getEmptyLegRequestsWithBrokers();
    fetchEmptyLegRequests();
  }

  Future<Position?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Step 1: Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Location services are disabled.')),
      );
      return null;
    }

    // Step 2: Check current permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Location permission denied by user.')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '❗ Location permission permanently denied. Open settings.')),
      );
      await Geolocator.openAppSettings();
      return null;
    }

    // Step 3: Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      // Animate the camera to the new location
      animateCamera(_currentLocation, 10.0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '📍 Location: ${position.latitude}, ${position.longitude}')),
      );
      return position;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚫 Error fetching location: $e')),
      );
      return null;
    }
  }

  Future<void> fetchEmptyLegRequests() async {
    setState(() {
      _isLoading = true; // Show progress bar
    });

    FirestoreService firestoreService = FirestoreService(context);
    List<Map<String, dynamic>> requests =
        await firestoreService.getEmptyLegRequestsWithBrokers();

    setState(() {
      _isLoading = false; // Hide progress bar after data is fetched
    });

    if (requests.isNotEmpty) {
      print('requests Data');
      print(requests);
      // _filteredUsers = _buildCardStacks(context, requests);
      _filteredUsers = _buildBottomSheetList(context, requests);
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _onMarkerTap() {
    setState(() {
      _isSearchBarVisible = true; // Show the search bar when marker is tapped
    });
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
                animateCamera(_baseLocation, 10.0);

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

    // Animate the camera to the location
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: location, zoom: zoom),
    ));

    if (_isBaseSelected) {
      // Add or update green marker at the location
      Marker newMarker = Marker(
        markerId: MarkerId('base_location'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        // 👈 green color
        infoWindow: InfoWindow(title: 'Base Location'),
      );
      _markers.clear(); // Optional: if you only want one marker at a time
      _markers.add(newMarker);
    } else {
      // Add or update green marker at the location
      Marker newMarker = Marker(
        markerId: MarkerId('current_location'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        // 👈 green color
        infoWindow: InfoWindow(title: 'Current Location'),
      );
      _markers.clear(); // Optional: if you only want one marker at a time
      _markers.add(newMarker);
    }

    // Trigger UI update (make sure you're in a stateful widget)
    setState(() {});
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

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Center(
                    child: Text(
                      'Available at',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Divider
                  const Divider(thickness: 1, color: Colors.grey),
                  const SizedBox(height: 20),

                  // Toggle section
                  Row(
                    children: [
                      // Base option
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isBaseSelected = true; // Select "Base"
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _isBaseSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                              border: Border.all(
                                color:
                                    _isBaseSelected ? Colors.blue : Colors.grey,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Base',
                                style: TextStyle(
                                  color: _isBaseSelected
                                      ? Colors.white
                                      : Colors.black,
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
                              _isBaseSelected = false; // Select "Current"
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: !_isBaseSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              border: Border.all(
                                color: !_isBaseSelected
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Current',
                                style: TextStyle(
                                  color: !_isBaseSelected
                                      ? Colors.white
                                      : Colors.black,
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
                  MaterialButton(
                    onPressed: () async {
                      // Determine the selected location
                      _selectedLocation =
                          _isBaseSelected ? _baseLocation : _currentLocation;

                      if (_isBaseSelected) {
                        animateCamera(_baseLocation, 10.0);
                        _updateBaseLocation(_baseLocation.longitude,
                            _baseLocation.longitude, false);
                      } else {
                        animateCamera(_currentLocation, 10.0);
                        _updateCurrentLocation(_currentLocation.latitude,
                            _currentLocation.longitude);
                      }
                      // Show Snackbar
                      String message = _isBaseSelected
                          ? "You are available at Base Location"
                          : "You are available at Current Location";

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                    color: Colors.blue,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const SizedBox(
                      width: 250,
                      child: Center(child: Text('Confirm')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

/*  CardStackWidget _buildCardStackWidget(BuildContext context) {
    return CardStackWidget(
      opacityChangeOnDrag: true,
      swipeOrientation: CardOrientation.both,
      cardDismissOrientation: CardOrientation.both,
      positionFactor: 3,
      scaleFactor: 1.5,
      alignment: Alignment.center,
      reverseOrder: true,
      animateCardScale: true,
      dismissedCardDuration: const Duration(milliseconds: 150),
      cardList: _filteredUsers,
    );
  }*/

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

  List<CardModel> _buildCardStacks(
      BuildContext context, List<Map<String, dynamic>> brokerDataList) {
    final double containerWidth = MediaQuery.of(context).size.width - 50;

    var list = <CardModel>[];

    for (var brokerData in brokerDataList) {
      var brokerProfile = brokerData['broker'] ?? {};
      String userName = brokerProfile['name']?.toString() ?? 'Unknown Broker';
      String userImage = brokerProfile['profilePictureUrl']?.toString() ??
          'https://via.placeholder.com/150';
      String id = brokerProfile['brokerID']?.toString() ?? 'dfdf ID';

      // Access nodeID directly from brokerData
      String nodeID =
          brokerData['emptyLegRequestID']?.toString() ?? 'nodeID Not Found';

      double rating = Random().nextDouble() * 5; // Placeholder rating
      print('emptyLegRequestID------------------------');
      print(nodeID);

      list.add(
        CardModel(
          backgroundColor: Colors.white,
          shadowColor: Colors.black.withOpacity(0.2),
          child: GestureDetector(
            onTap: () {
              // Ensure that the correct brokerID and nodeID are passed to the next screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectBroker(
                    brokerID: id,
                    // Passing the correct brokerID for the selected card
                    emptyLegRequestID:
                        nodeID, // Passing the correct nodeID for the selected card
                  ),
                ),
              );
            },
            child: SizedBox(
              height: 150,
              width: containerWidth,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 25.0,
                            direction: Axis.horizontal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return list;
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
      String id = brokerProfile['brokerID']?.toString() ?? 'dfdf ID';
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
              target: _baseLocation, // Initial position for the map
              zoom: 10.0, // Zoom level
            ),
            markers: _markers, // Pass _markers directly, no need for .toSet()
            onMapCreated: (GoogleMapController controller) {
              _mapController
                  .complete(controller); // Store the controller if needed
            },
            onTap: (LatLng latLng) {
              // Optional: Add logic to handle map taps if needed
              print('Marker tapped!');
            },
          ),

          // Conditionally show the progress bar
          if (_isLoading)
            Center(
              child:
                  CircularProgressIndicator(), // Progress indicator in the center
            ),

          if (_isSearchBarVisible) // Conditionally render the search bar
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: TextField(
                            onSubmitted: (value) {
                              // Call your search method with the entered text
                              _onSearchAirport(value);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search Location',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Suggest country codes based on the search
                    if (airportList.isNotEmpty)
                      SingleChildScrollView(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          // Avoid nested scrolling issues
                          itemCount: airportList.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(airportList[index].name.toString()),
                              onTap: () {
                                print("Clicked on: ${airportList[index].name}");
                                _onCountrySelected(airportList[index]);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

          Positioned.fill(
            child: _buildRadarAnimation(), // Radar animation always visible
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.5, // Sheet visible just a bit initially
            minChildSize: 0.2, // Minimum height (closed state)
            maxChildSize: 0.8, // Half screen height
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
}

class RadarPainter extends CustomPainter {
  final double radius;

  RadarPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
