/*
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});



  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    print("Latitude: ${_locationData.latitude}, Longitude: ${_locationData.longitude}");
    // Now you have the user's location in _locationData
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hi, nice to meet you!',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              const Center(
                child: Text(
                  'Please turn on your device location to proceed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              InkWell(
                onTap: () {
                  // Add your click handling logic here
                  _getCurrentLocation(); // Make sure to add parentheses here
                  // You can replace the above print statement with your actual logic
                },
                child: Container(
                  width: 250.0,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Colors.brown,
                      width: 2.0,
                    ),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text('Use current location'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0.0,
            child: Image.asset(
              'assets/img_bottom_building.png',
              height: 100.0,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}*/
