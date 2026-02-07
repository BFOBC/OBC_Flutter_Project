import 'package:broker_flutter_pp/ui/auth/screens/Login.dart';
import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/SplashScreen.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/bridges/AirportService.dart';


class DataSyncScreen extends StatefulWidget {
  const DataSyncScreen({Key? key}) : super(key: key);

  @override
  State<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<DataSyncScreen> {
  String statusMessage = 'Starting synchronization...';

  @override
  void initState() {
    super.initState();
    startSyncProcess();
  }

  Future<void> startSyncProcess() async {
    int retryCount = 0;

    while (true) {
      // 🔌 Internet check
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() => statusMessage = 'No internet connection. Please connect to the internet.');
        await Future.delayed(const Duration(seconds: 5));
        continue; // wait and try again
      }

      try {
        setState(() => statusMessage = 'Fetching data (attempt ${retryCount + 1})...');
        await Future.delayed(const Duration(seconds: 1));

        final AirportService service = AirportService();
        await service.loadAirports();

        setState(() => statusMessage = 'Data synchronized. Requesting location permission...');
        await Future.delayed(const Duration(seconds: 1));

        // ✅ Save sync flag
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDataSynced', true);

        await handleLocationPermission(); // ye navigate karega
        break; // exit loop if all done
      } catch (e) {
        retryCount++;
        setState(() => statusMessage = 'Sync failed (attempt $retryCount). Retrying in ${2 * retryCount} seconds...');
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
  }


  Future<void> handleLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      checkRememberMe(context); // ✅ function now declared properly

/*      // Navigate to login/home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );*/
    } else {
      showLocationDialog();
      //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required.')));
      // Optionally retry or stay on screen
    }
  }

  void checkRememberMe(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('rememberMe') ?? false;

    print("rememberMe: $rememberMe");
    if (rememberMe) {
      String email = prefs.getString('email') ?? '';
      String password = prefs.getString('password') ?? '';
      String? roleStr = prefs.getString('role');

      print("✅ Current Shared Preferences:");
      print("Email: ${prefs.getString('email')}");
      print("Password: ${prefs.getString('password')}");
      print("Role: ${prefs.getString('role')}");
      print("Remember Me: ${prefs.getBool('rememberMe')}");

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // ✅ Set role in RoleProvider
        if (roleStr != null) {
          final roleProvider = Provider.of<RoleProvider>(context, listen: false);
          roleProvider.setRole(roleStr == 'Broker' ? UserRole.broker : UserRole.courier);
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DrawerScreen()),
        );
      } catch (e) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginCard()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginCard()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF6FB1FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Premium Circular Loader (Native)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.06),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF4A90E2)),
                        ),
                      ),
                    ),

                  ),

                  const SizedBox(height: 28),

                  /// Title
                  const Text(
                    "Hang tight!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// Dynamic Status Message
                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// Linear Progress (Secondary indicator)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                      width: 180,
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF4A90E2)),
                        backgroundColor: Color(0xFFE3F2FD),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Info Text
                  const Text(
                    "Slow network connections may take a bit longer.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
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
  void showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_off,
                  size: 50,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Location Permission Required",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "This app requires location permission to work properly. Please enable location to continue.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          handleLocationPermission(); // Retry
                        },
                        child: const Text("Retry"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          openAppSettings();
                        },
                        child: const Text("Open Settings"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }


}
