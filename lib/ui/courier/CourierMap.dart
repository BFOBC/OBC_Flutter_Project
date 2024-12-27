import 'dart:math';
import 'package:broker_flutter_pp/ui/courier/SelectBroker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:card_stack_widget/card_stack_widget.dart';
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
  List<CardModel> _filteredUsers = [];
  bool _isSearching = false;
  bool _isSearchBarVisible = true; // Visibility state for search bar
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;
  bool _isBaseSelected = true;
  String _searchText = ""; // This holds the text in the search bar
  String brokerName = '';
  String brokerContact = '';
  String country='';
  String currentLocation='';
  bool isLoading = true;

  // Add a MapController to control the map
  late MapController _mapController;
  //Location location = Location(); // Create a Location instance


  LatLng _baseLocation =
      const LatLng(40.7128, -74.0060); // Example: New York City
  LatLng _currentLocation =
      const LatLng(34.0522, -118.2437); // Example: Los Angeles
  late LatLng _selectedLocation; // Will store the currently selected location
  List<Map<String, dynamic>> brokerInfoList = [];

  List<AirportModel> airportList = [];
  List<Marker> _markers = [];
  late User _currentUser;


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
    _mapController = MapController();
    _currentUser = FirebaseAuth.instance.currentUser!;
   // _getCurrentLocation();
    //_onSearch("abc");
    // fetchBrokerDetails();
  }
/*  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location
    LocationData _locationData = await location.getLocation();

    setState(() {
      _currentLocation = LatLng(_locationData.latitude!, _locationData.longitude!);

      // Update the map and markers
      _mapController.move(_currentLocation, 15.0);
      _markers = [
        Marker(
          width: 80.0,
          height: 80.0,
          point: _baseLocation,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      ];
    });
  }*/
  Future<void> fetchBrokerDetails() async {
    try {
      // Fetch all broker documents from Firestore
      QuerySnapshot brokerDocsSnapshot =
          await FirebaseFirestore.instance.collection('broker').get();

      if (brokerDocsSnapshot.docs.isNotEmpty) {
        setState(() {
          // Create a list of broker data
          brokerInfoList = brokerDocsSnapshot.docs.map((doc) {
            return {
              'name': doc['name'] ?? 'Unknown Broker',
              'contact': doc['contact'] ?? 'No Contact Info',
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          // If no brokers are found
          brokerInfoList = [
            {
              'name': 'No Brokers Found',
              'contact': '',
              'image': '',
              'rating': 0.0
            }
          ];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        brokerInfoList = [
          {
            'name': 'Error fetching data',
            'contact': '',
            'image': '',
            'rating': 0.0
          }
        ];
        isLoading = false;
      });
      print('Error: $e');
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

              // Update the map and markers (UI updates)
              setState(() {
                country=airportItem.countryCode.toString();
                print("country $country");
                _baseLocation = latLng; // Update the selected location
                _mapController.move(_baseLocation, 8.0); // Animate to the new location
                _markers = [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _baseLocation,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ];
                _searchText = "";
                _suggestedCountries = [];
                airportList = [];
              });
              // Call Firebase to update the base location asynchronously
              _updateBaseLocation(lat, long);
            } catch (e, stackTrace) {
              print("Error in onConfirm: $e");
              print(stackTrace);
            }
          },
        );
      },
    );
  }

  Future<void> _updateBaseLocation(double lat, double long) async {
    try {
      // Perform Firebase update asynchronously without blocking the UI
      await FirebaseFirestore.instance
          .collection('courier')
          .doc(_currentUser.uid)
          .set({
        'baseLocationLat': lat,
        'baseLocationLong': long,
        'country': country,
        'base': _isBaseSelected,
        'current': !_isBaseSelected,
      }, SetOptions(merge: true));

      // Firebase update completed
      print("Base location updated successfully!");
    } catch (e) {
      // Handle Firebase errors
      print("Error updating base location: $e");
    }
  }


  void _onSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });

      _radarController.forward().then((_) {
        setState(() {
          _isSearching = false;
          _showCardStack = true;
          _filteredUsers = _buildMockList(context, size: 2);
        });
      });
    } else {
      setState(() {
        _showCardStack = false;
        _isSearching = false;
      });
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              color: _isBaseSelected ? Colors.blue : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                              border: Border.all(
                                color: _isBaseSelected ? Colors.blue : Colors.grey,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Base',
                                style: TextStyle(
                                  color: _isBaseSelected ? Colors.white : Colors.black,
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
                              color: !_isBaseSelected ? Colors.blue : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              border: Border.all(
                                color: !_isBaseSelected ? Colors.blue : Colors.grey,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Current',
                                style: TextStyle(
                                  color: !_isBaseSelected ? Colors.white : Colors.black,
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

                      // Move the map to the selected location
                      _mapController.move(_selectedLocation, 8.0);

                      // Add a marker at the selected location (optional)
                      /*_markers = [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _selectedLocation,
                        builder: (ctx) => const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ];*/

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


  CardStackWidget _buildCardStackWidget(BuildContext context) {
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
  }

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

  List<CardModel> _buildMockList(BuildContext context, {int size = 0}) {
    final double containerWidth = MediaQuery.of(context).size.width - 50;

    var list = <CardModel>[];
    for (int i = 0; i < size; i++) {
      // var color = Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
      var color = Colors.white;

      var userName = 'Broker ${i + 1}';
      var userImage = 'https://via.placeholder.com/150';
      var rating = Random().nextDouble() * 5;
      var brokerID;

      list.add(
        CardModel(
          backgroundColor: color,
          shadowColor: Colors.black.withOpacity(0.2),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectBroker(
                    brokerID: brokerID,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(30.3753, 69.3451),
              initialZoom: 5.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
              markers: _markers,
            ),
            ],
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
          Positioned(
            bottom: 20.0,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 300,
                child:
                    _buildCardStackWidget(context), // Card stack always visible
              ),
            ),
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
