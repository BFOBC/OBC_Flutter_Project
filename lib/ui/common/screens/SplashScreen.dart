import 'dart:async';
import 'package:broker_flutter_pp/ui/auth/screens/Login.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add a delay to simulate the splash screen duration
    Timer(const Duration(seconds: 3), () {
      checkLocationPermissions();
    });
  }

  Future<void> checkLocationPermissions() async {
    // Check if location permissions are already granted
    if (await Permission.location.isGranted) {
      // Permissions are already granted, navigate to login screen
      navigateToLoginScreen();
    } else {
      // Permissions are not granted, navigate to permission screen
      navigateToPermissionScreen();
    }
  }

  void navigateToLoginScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginCard(),
       // builder: (context) =>  CircularChartScreen(),
      ),
    );
  }

  void navigateToPermissionScreen() {
    final Map<String, double> chartData = {
      "Red": 40,
      "Green": 30,
      "Blue": 30,
    };

    final List<Color> chartColors = [
      Colors.black,
      Colors.green,
      Colors.blue,
    ];
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
       // builder: (context) => const PermissionScreen(),
        // Define the data and colors

         //  builder: (context) =>                OpenStreetMapScreen(),
          // builder: (context) =>                AddNewEmptyLegScreen(),
           builder: (context) =>                LoginCard(),

      //  builder: (context) =>  CircularChartScreen(dataMap: chartData,
        //  colorList: chartColors),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your splash screen content, such as an app logo or name
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/broker.jpg'), // Replace with your image asset path
            )  ,
            SizedBox(height: 16.0),
            Text(
              ''
                  'OBC',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}