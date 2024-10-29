import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase before running the app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FirebaseStatusScreen(),
    );
  }
}

class FirebaseStatusScreen extends StatefulWidget {
  @override
  _FirebaseStatusScreenState createState() => _FirebaseStatusScreenState();
}

class _FirebaseStatusScreenState extends State<FirebaseStatusScreen> {
  bool _isFirebaseInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _isFirebaseInitialized = true;
      });
      _showSnackbar('Firebase Initialized Successfully');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackbar('Error initializing Firebase: $_errorMessage');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Firebase Status")),
      body: Center(
        child: _isFirebaseInitialized
            ? Text("Firebase is connected!")
            : Text("Initializing Firebase..."),
      ),
    );
  }
}
