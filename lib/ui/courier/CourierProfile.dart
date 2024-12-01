import 'dart:io';
import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Visa.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/CourierProfileData.dart';

class CourierProfile extends StatefulWidget {
  final CourierProfileData courierProfile;

  const CourierProfile({
    Key? key,
    required this.courierProfile, required List visas, required List passports,
  }) : super(key: key);

  @override
  _CourierProfileState createState() => _CourierProfileState();
}
class _CourierProfileState extends State<CourierProfile> {
  
  late User _currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  TextEditingController _nameController = TextEditingController();
  List<TextEditingController> _visaCountryControllers = [];
  List<TextEditingController> _visaExpiryControllers = [];
  List<TextEditingController> _passportCountryControllers = [];
  List<TextEditingController> _passportExpiryControllers = [];
  List<Visa> visas = [];
  List<Passport> passports = [];
  String? _profilePictureUrl;
  bool _hasCar = false; // State for the switch
  bool _willingToDoFirstLastMile = false; // State for the switch
  bool _hasDrivingLicence = false; // State for the switch

  late CourierProfileData _editableProfile;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser!;
    final doc = await _firestore.collection('courier').doc(_currentUser.uid).get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      setState(() {
        visas = (doc['visas'] as List<dynamic>?)
                ?.map((item) => Visa.fromMap(item))
                .toList() ??
            [];
        passports = (doc['passports'] as List<dynamic>?)
                ?.map((item) => Passport.fromMap(item))
                .toList() ??
            [];
        _nameController.text = doc['name'] ?? 'N/A';
        widget.courierProfile.email = _currentUser .email; // Assuming email is part of courierProfile
        widget.courierProfile.id = _currentUser .uid;
      });
    }
  }

  Future<void> _updateFirestore(String field, dynamic value) async {
    try {
        await _firestore.collection('courier').doc(_currentUser.uid).set({
    'name': _nameController.text.isEmpty ? 'N/A' : _nameController.text,
    'email': _currentUser.email,
    'profilePictureUrl': _profilePictureUrl,
    'visas': List<Visa>,
    'passports': List<Passport>,
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Profile saved successfully!')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error saving profile: $e')),
  );
}
  }

Future<void> _fetchProfileData() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final userUID = currentUser.uid;
    final email = currentUser.email;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('courier')
        .doc(userUID)
        .get();

    if (doc.exists) {
      setState(() {
        _editableProfile = CourierProfileData.fromMap(doc.data() as Map<String, dynamic>);
      });
    } else {
      // Initialize default profile
      setState(() {
        _editableProfile = CourierProfileData(
          courierID: userUID,
          name: "",
          email: currentUser.email ?? "N/A",
          visas: [],
          passports: [],
        );
      });
    }
  } catch (e) {
    print("Error fetching profile: $e");
  }
}

Future<void> _saveProfile() async {
    try {

      await _firestore.collection('courier').doc(_currentUser.uid).set({
        'name': _nameController.text.isEmpty ? 'N/A' : _nameController.text,
        'email': _currentUser.email,
        'profilePictureUrl': _profilePictureUrl,
        'visas': List<Visa>,
        'passports': List<Passport>,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = 'profile_pictures/${_currentUser.uid}.jpg';
      try {
        TaskSnapshot uploadTask =
            await _storage.ref(fileName).putFile(file);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          _profilePictureUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture uploaded successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading picture: $e')),
        );
      }
    }
  }

 void _showEditDialog({
    required String type,
    Visa? visa,
    Passport? passport,
  }) {
    TextEditingController countryController = TextEditingController();
    TextEditingController expiryController = TextEditingController();

    if (visa != null || passport != null) {
      countryController.text = visa?.countryName ?? passport?.countryName ?? '';
      expiryController.text = visa?.expiryDate ?? passport?.expiryDate ?? '';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(visa != null || passport != null ? 'Edit $type' : 'Add $type'),
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
              onPressed: () async {
                if (type == 'Visa') {
                  Visa newVisa = Visa(
                    countryName: countryController.text,
                    expiryDate: expiryController.text,
                  );
                  if (visa != null) {
                    visas.remove(visa);
                  }
                  visas.add(newVisa);
                  await _updateFirestore('visas', visas.map((v) => v.toMap()).toList());
                } else if (type == 'Passport') {
                  Passport newPassport = Passport(
                    countryName: countryController.text,
                    passportNumber: passport?.passportNumber ?? '',
                    expiryDate: expiryController.text,
                    issueDate: passport?.issueDate ?? '',
                  );
                  if (passport != null) {
                    passports.remove(passport);
                  }
                  passports.add(newPassport);
                  await _updateFirestore('passports', passports.map((p) => p.toMap()).toList());
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
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
  
  void _showDeleteConfirmation({
    required String type,
    Visa? visa,
    Passport? passport,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete $type'),
          content: Text('Are you sure you want to delete this $type?'),
          actions: [
            TextButton(
              onPressed: () async {
                if (type == 'Visa' && visa != null) {
                  visas.remove(visa);
                  await _updateFirestore('visas', visas.map((v) => v.toMap()).toList());
                } else if (type == 'Passport' && passport != null) {
                  passports.remove(passport);
                  await _updateFirestore(
                      'passports', passports.map((p) => p.toMap()).toList());
                }
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
  _showAddDialog(String type) {
    TextEditingController countryController = TextEditingController();
    TextEditingController expiryController = TextEditingController();
    TextEditingController passportNumberController = TextEditingController();
    TextEditingController issueDateController = TextEditingController();

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
                    widget.courierProfile.visas.add(Visa(
                      countryName: countryController.text,
                      expiryDate:  DateTime.parse(expiryController.text).toString(),
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
                    widget.courierProfile.passports.add(Passport(
                      countryName: countryController.text,
                      passportNumber: "test134",
                      expiryDate:  DateTime.parse(expiryController.text).toString(),
                      issueDate:  DateTime.parse(expiryController.text).toString(),
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

  Future<void> _saveCourierProfile() async {
  try {
    _editableProfile.name = _nameController.text; // Sync name
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final data = widget.courierProfile.toMap();
    await FirebaseFirestore.instance
        .collection('courier')
        .doc(currentUser.uid)
        .set(data, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully')),
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
                backgroundImage: widget.courierProfile.profilePictureUrl?.isNotEmpty == true
                ? NetworkImage(widget.courierProfile.profilePictureUrl!)
                : AssetImage('assets/avatar.png') as ImageProvider,

                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: Icon(Icons.edit, color: Colors.white, size: 16,),
                    onPressed: _uploadProfilePicture,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // Profile Information in rounded containers with white backgrounds
              _buildProfileField('ID', widget.courierProfile.id.toString()),
              const SizedBox(height: 10),
              _buildNonEditableField('Email', _currentUser .email ?? 'N/A'),
               const SizedBox(height: 10),
              _buildEditableField('Name', _nameController),
               const SizedBox(height: 10),

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
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Willing to do first/last mile?', style: TextStyle(fontSize: 16)),
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
              // Save Button
              ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a field for displaying a profile entry (e.g., Name, ID, etc.)
  Widget _buildProfileField(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

   Widget _buildEditableField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }


  Widget _buildVisaList() {
    return Column(
      children: [
        const Text('Visas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          itemCount: visas.length,
          itemBuilder: (context, index) {
            final visa = visas[index];
            return ListTile(
              title: Text(visa.countryName),
              subtitle: Text('Expiry: ${visa.expiryDate}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showEditDialog(type: 'Visa', visa: visa),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(type: 'Visa', visa: visa),
                  ),
                ],
              ),
            );
          },
        ),
        ElevatedButton.icon(
          onPressed: () => _showEditDialog(type: 'Visa'),
          icon: Icon(Icons.add),
          label: Text('Add Visa'),
        ),
      ],
    );
  }

  Widget _buildPassportList() {
    return Column(
      children: [
        const Text('Passports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          itemCount: passports.length,
          itemBuilder: (context, index) {
            final passport = passports[index];
            return ListTile(
              title: Text(passport.countryName),
              subtitle: Text('Expiry: ${passport.expiryDate}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showEditDialog(type: 'Passport', passport: passport),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        _showDeleteConfirmation(type: 'Passport', passport: passport),
                  ),
                ],
              ),
            );
          },
        ),
        ElevatedButton.icon(
          onPressed: () => _showEditDialog(type: 'Passport'),
          icon: Icon(Icons.add),
          label: Text('Add Passport'),
        ),
      ],
    );
  }

Widget _buildNonEditableField(String label, String value) {
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