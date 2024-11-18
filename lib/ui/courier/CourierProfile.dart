import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'models/CourierProfileData.dart';
import 'models/Visa.dart';
import 'models/Passport.dart';

class CourierProfile extends StatefulWidget {
  final List<Visa> visas;
  final List<Passport> passports;
  final CourierProfileData courierProfile;

  const CourierProfile({
    super.key,
    required this.courierProfile,
    required this.visas,
    required this.passports,
  });

  @override
  _CourierProfileState createState() => _CourierProfileState();
}

class _CourierProfileState extends State<CourierProfile> {
  List<TextEditingController> _visaCountryControllers = [];
  List<TextEditingController> _visaExpiryControllers = [];
  List<TextEditingController> _passportCountryControllers = [];
  List<TextEditingController> _passportExpiryControllers = [];
  bool _hasCar = false; // State for the switch
  bool _willingToDoFirstLastMile = false; // State for the switch
  bool _hasDrivingLicence = false; // State for the switch

  @override
  void initState() {
    super.initState();
    // Initialize controllers for existing visas and passports
    _visaCountryControllers = widget.visas
        .map((visa) => TextEditingController(text: visa.countryName))
        .toList();
    _visaExpiryControllers = widget.visas
        .map((visa) => TextEditingController(text: visa.expiryDate))
        .toList();
    _passportCountryControllers = widget.passports
        .map((passport) => TextEditingController(text: passport.countryName))
        .toList();
    _passportExpiryControllers = widget.passports
        .map((passport) => TextEditingController(text: passport.expiryDate))
        .toList();
  }

  @override
  void dispose() {
    // Dispose of all controllers when the widget is disposed
    for (var controller in _visaCountryControllers) {
      controller.dispose();
    }
    for (var controller in _visaExpiryControllers) {
      controller.dispose();
    }
    for (var controller in _passportCountryControllers) {
      controller.dispose();
    }
    for (var controller in _passportExpiryControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Function to show dialog for adding new Visa/Passport
  void _showAddDialog(String type) {
    TextEditingController countryController = TextEditingController();
    TextEditingController expiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add $type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: countryController,
                decoration: InputDecoration(hintText: 'Country'),
              ),
              TextField(
                controller: expiryController,
                decoration: InputDecoration(hintText: 'Expiry Date'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (type == 'Visa') {
                  setState(() {
                    // Add the new visa to the list
                    widget.visas.add(Visa(
                      countryName: countryController.text,
                      expiryDate: expiryController.text,
                    ));
                    // Also, add controllers for the new visa
                    _visaCountryControllers.add(
                        TextEditingController(text: countryController.text));
                    _visaExpiryControllers.add(
                        TextEditingController(text: expiryController.text));
                  });
                } else if (type == 'Passport') {
                  setState(() {
                    // Add the new passport to the list
                    widget.passports.add(Passport(
                      countryName: countryController.text,
                      expiryDate: expiryController.text,
                    ));
                    // Also, add controllers for the new passport
                    _passportCountryControllers.add(
                        TextEditingController(text: countryController.text));
                    _passportExpiryControllers.add(
                        TextEditingController(text: expiryController.text));
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Function to show confirmation dialog for deletion
  void _showDeleteConfirmation(int index, String type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete $type'),
          content: Text('Are you sure you want to delete this $type?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  if (type == 'Visa') {
                    // Remove the visa from the list
                    widget.visas.removeAt(index);
                    _visaCountryControllers.removeAt(index);
                    _visaExpiryControllers.removeAt(index);
                  } else if (type == 'Passport') {
                    // Remove the passport from the list
                    widget.passports.removeAt(index);
                    _passportCountryControllers.removeAt(index);
                    _passportExpiryControllers.removeAt(index);
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _saveCourierProfile() async {
  try {
    final data = widget.courierProfile.toMap();

    print("Saving data: $data"); // Debugging the data to verify output

    await FirebaseFirestore.instance
        .collection('couriers')
        .doc(widget.courierProfile.courierID)
        .set(data);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile saved successfully!')),
    );
  } catch (e) {
    print("Error saving profile: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save profile: $e')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Courier Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/avatar.png'),
              ),
              const SizedBox(height: 20),
              // Profile Information in rounded containers with white backgrounds
              _buildProfileField('ID', widget.courierProfile.id),
              const SizedBox(height: 10),
              _buildProfileField('Name', widget.courierProfile.name),
              const SizedBox(height: 10),
              _buildNonEditableField('Email', widget.courierProfile.email),
              // Email non-editable
              const SizedBox(height: 5),

              // Visa List
              _buildVisaList(),
              const SizedBox(height: 20),

              // Passport List
              _buildPassportList(),
              const SizedBox(height: 20),
              // Card widget
              Card(
                elevation: 4, // Adds shadow effect to the card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Do you have a car?', style: TextStyle(fontSize: 16)),
                          Switch(
                            value: _hasCar,
                            onChanged: (value) {
                              setState(() {
                                _hasCar = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(), // Optional divider between switches
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Do you have a driving licence?', style: TextStyle(fontSize: 16)),
                          Switch(
                            value: _hasDrivingLicence,
                            onChanged: (value) {
                              setState(() {
                                _hasDrivingLicence = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(), // Optional divider between switches
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Willing to do first and last mile?', style: TextStyle(fontSize: 16)),
                          Switch(
                            value: _willingToDoFirstLastMile,
                            onChanged: (value) {
                              setState(() {
                                _willingToDoFirstLastMile = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              ElevatedButton(
                onPressed: () async {
                  // Add your save logic here
                  print("Saving profile...");
                  await _saveCourierProfile();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisaList() {
    return _buildListCard(
        'Visas', _visaCountryControllers, _visaExpiryControllers);
  }

  Widget _buildPassportList() {
    return _buildListCard(
        'Passports', _passportCountryControllers, _passportExpiryControllers);
  }

  Widget _buildListCard(
      String title,
      List<TextEditingController> countryControllers,
      List<TextEditingController> expiryControllers) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < countryControllers.length; i++)
            _buildCardDetails(
                i, countryControllers[i], expiryControllers[i], title),
          TextButton(
            onPressed: () =>
                _showAddDialog(title == 'Visas' ? 'Visa' : 'Passport'),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails(int index, TextEditingController countryController,
      TextEditingController expiryController, String type) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10.0),
      child: ListTile(
        title: Text(countryController.text),
        subtitle: Text('Expiry Date: ${expiryController.text}'),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(index, type),
        ),
      ),
    );
  }

  // Helper widget for each profile field
  Widget _buildProfileField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white, // White background for the container
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for non-editable field (like email)
  Widget _buildNonEditableField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white, // White background for the container
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
