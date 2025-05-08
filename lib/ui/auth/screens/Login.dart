import 'package:broker_flutter_pp/ui/auth/screens/TestScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/utils/dialog_utils.dart';
import 'package:broker_flutter_pp/ui/common/utils/validator.dart';
import '../../../data/FirestoreService.dart';
import '../../common/screens/DrawerScreen.dart';
import '../../common/utils/RoleProvider.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardView(),
            ],
          ),
        ),
      ),
    );
  }
}

class CardView extends StatefulWidget {
  const CardView({super.key});

  @override
  _CardViewState createState() => _CardViewState();
}

class _CardViewState extends State<CardView> {
  final TextEditingController _emailController =
      TextEditingController(text: 'broker@gmail.com');
  final TextEditingController _passwordController =
      TextEditingController(text: '123456');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selectedIndex = 0;

  String get emailHint =>
      _selectedIndex == 0 ? 'Enter Broker Email' : 'Enter Courier Email';

  final List<bool> _selectedToggle = [true, false];
  final List<String> _toggleText = ["Broker", "Courier"];

  Future<void> _submitForm() async {
    print("SubmitForm called");

    if (_formKey.currentState!.validate()) {
      print("Form validated");

      showProgressDialog(context);

      try {
        final roleProvider = Provider.of<RoleProvider>(context, listen: false);
        final role = _selectedIndex == 0 ? UserRole.broker : UserRole.courier;
        roleProvider.setRole(role);

        String? errorMessage = await signInAndSaveUser(
          _emailController.text.trim(),
          _passwordController.text,
          _selectedIndex,
        );

        print("Calling signInAndSaveUser...");

        // Hide progress only once here
        if (context.mounted) hideProgressDialog(context);

        if (errorMessage == null) {
          print("Login successful — navigating to DrawerScreen");
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DrawerScreen()),
            );
          }
        } else {
          print("Login failed — showing SnackBar: $errorMessage");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) hideProgressDialog(context);

        print("Exception occurred: $e");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Something went wrong. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print("Form validation failed");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fix the errors in the form"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }


  Future<String?> signInAndSaveUser(
      String email, String password, int selectedIndex) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Add logging to confirm successful login
      print("Login successful: ${userCredential.user?.uid}");

      // Save user info in Firestore (optional)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'role': selectedIndex == 0 ? 'broker' : 'courier',
      }, SetOptions(merge: true));

      return null; // no error
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      return e.message;
    } catch (e) {
      print("Unknown error: $e");
      return "Something went wrong. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: IntrinsicWidth(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: _selectedToggle,
                  onPressed: (int index) {
                    setState(() {
                      _selectedIndex = index;
                      _selectedToggle[index] = true;
                      _selectedToggle[1 - index] = false;
                      if (_selectedIndex == 0) {
                        _emailController.text = 'broker@gmail.com';
                      } else {
                        _emailController.text = 'courier@gmail.com';
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  selectedBorderColor: Colors.grey,
                  selectedColor: Colors.white,
                  fillColor: Palette.primaryColor,
                  color: Colors.black,
                  constraints:
                      const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                  children: _toggleText.map((text) => Text(text)).toList(),
                ),
                const SizedBox(height: 20.0),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: emailHint,
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return Validator.validateEmail(email: value ?? '');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Enter Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return Validator.validatePassword(
                              password: value ?? '');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                MaterialButton(
                  onPressed: _submitForm,
                  color: Colors.blue,
                  textColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const SizedBox(
                      width: 250, child: Center(child: Text('Login'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
