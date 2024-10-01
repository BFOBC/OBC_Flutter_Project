import 'package:flutter/material.dart';

/*void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Toggle Screen',
      home: ToggleLoginRegisterScreen(),
    );
  }
}*/

class ToggleLoginRegisterScreen extends StatefulWidget {
  @override
  _ToggleLoginRegisterScreenState createState() => _ToggleLoginRegisterScreenState();
}

class _ToggleLoginRegisterScreenState extends State<ToggleLoginRegisterScreen> {
  // Index to keep track of selected screen
  int _selectedIndex = 0;

  // Toggle button options
  final List<bool> _selectedToggle = [true, false];

  // Toggle button text
  final List<String> _toggleText = ["Login", "Register"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login/Register Toggle Screen"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Toggle Buttons
          ToggleButtons(
            isSelected: _selectedToggle,
            onPressed: (int index) {
              setState(() {
                _selectedIndex = index;
                _selectedToggle[index] = true;
                _selectedToggle[1 - index] = false;
              });
            },
            borderRadius: BorderRadius.circular(10),
            selectedBorderColor: Colors.blue,
            selectedColor: Colors.white,
            fillColor: Colors.blueAccent,
            color: Colors.black,
            constraints: BoxConstraints(minHeight: 40.0, minWidth: 100.0),
            children: _toggleText.map((text) => Text(text)).toList(),
          ),
          SizedBox(height: 20),
          // Conditional rendering of screens based on the toggle selection
          _selectedIndex == 0 ? LoginScreen() : RegisterScreen(),
        ],
      ),
    );
  }
}

// Login Screen
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          SizedBox(height: 10),
          TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle login logic
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}

// Register Screen
class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
          ),
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          SizedBox(height: 10),
          TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle registration logic
            },
            child: Text('Register'),
          ),
        ],
      ),
    );
  }
}
