import 'package:broker_flutter_pp/ui/broker/data/BrokerProfileData.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BrokerProfileScreen extends StatefulWidget {

  final BrokerProfileData brokerProfile;

  const BrokerProfileScreen({super.key, required this.brokerProfile});
  @override
  _BrokerProfileScreenState createState() => _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends State<BrokerProfileScreen> {
  late User _currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _paymentTermsController = TextEditingController();
  List<TextEditingController> _licenseControllers = [];
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser!;
    DocumentSnapshot profileSnapshot =
        await _firestore.collection('broker').doc(_currentUser.uid).get();

    if (profileSnapshot.exists) {
      Map<String, dynamic> data = profileSnapshot.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? 'N/A';
      _websiteController.text = data['website'] ?? 'N/A';
      _countryController.text = data['country'] ?? 'N/A';
      _paymentTermsController.text = data['paymentTerms'] ?? 'N/A';
      _licenseControllers = (data['license'] as List<dynamic>? ?? [])
          .map((license) => TextEditingController(text: license as String))
          .toList();
      _profilePictureUrl = data['profilePictureUrl'];
    } else {
      _licenseControllers = [TextEditingController()];
    }

    setState(() {});
  }

  Future<void> _saveProfile() async {
    try {
      final updatedLicenses = _licenseControllers.map((c) => c.text).toList();

      await _firestore.collection('broker').doc(_currentUser.uid).set({
        'name': _nameController.text.isEmpty ? 'N/A' : _nameController.text,
        'website': _websiteController.text.isEmpty ? 'N/A' : _websiteController.text,
        'country': _countryController.text.isEmpty ? 'N/A' : _countryController.text,
        'paymentTerms': _paymentTermsController.text.isEmpty ? 'N/A' : _paymentTermsController.text,
        'license': updatedLicenses,
        'email': _currentUser.email,
        'profilePictureUrl': _profilePictureUrl,
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

  void _removeLicenseField(int index) {
  setState(() {
    _licenseControllers.removeAt(index);
  });
}

void _addLicenseField() {
  setState(() {
    _licenseControllers.add(TextEditingController());
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broker Profile'),
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profilePictureUrl != null
                              ? NetworkImage(_profilePictureUrl!)
                              : const AssetImage('assets/avatar.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _uploadProfilePicture,
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProfileField('User ID', _currentUser.uid),
                    const SizedBox(height: 10),
                    _buildNonEditableField('Email', _currentUser.email ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildEditableField('Name', _nameController),
                    const SizedBox(height: 10),
                    _buildEditableField('Website', _websiteController),
                    const SizedBox(height: 10),
                    _buildEditableField('Country', _countryController),
                    const SizedBox(height: 10),
                    _buildEditableField('Payment Terms', _paymentTermsController),
                    const SizedBox(height: 20),
                    _buildLicenseCard(),
                    const SizedBox(height: 20),
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

  // Helper widget for each profile field
  Widget _buildProfileField(String label, String value) {
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


  Widget _buildLicenseCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
                const Text(
                  'Licenses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    ),
                    ),
                    const SizedBox(height: 10),
        // Render all license input fields
        for (int i = 0; i < _licenseControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _licenseControllers[i],
                      decoration: const InputDecoration(
                        hintText: 'Enter License',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.black45),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeLicenseField(i),
                  ),
                ],
              ),
            ),
          ),
        // Add License button
        Container(
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
          child: Row(
            children: [
              Expanded(
                child: Text(''), // Empty to align the button properly
              ),
              ElevatedButton(
                onPressed: _addLicenseField,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('Add License'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

}