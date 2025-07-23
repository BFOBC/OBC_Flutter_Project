import 'dart:convert';
import 'dart:io';
import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Visa.dart';
import 'package:broker_flutter_pp/ui/common/utils/toast_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/CourierProfileData.dart';
import 'package:http/http.dart' as http;

class CourierProfile extends StatefulWidget {
  // CourierProfileData courierProfile;

  CourierProfile({
    Key? key,
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
  late String name = '';
  bool _hasCar = false; // State for the switch
  bool _willingToDoFirstLastMile = false; // State for the switch
  bool _hasDrivingLicence = false; // State for the switch
  final TextEditingController _phoneController = TextEditingController();
  String _selectedPhoneNumber = "";
  bool _isLoading = true; // Add this flag to track the loading state
  late CourierProfileData _editableProfile;

  late CourierProfileData courierProfile = CourierProfileData();
  File? _image;
  String uploadedImageUrl = "";
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }
  Future<void> pickImageAndUpload() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      showCustomToast("User not logged in", isError: true);
      return;
    }

    final status = await Permission.photos.request();
    if (!status.isGranted) {
      showCustomToast("Permission denied", isError: true);
      return;
    }

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isUploading = true;
    });

    try {
      final url = Uri.parse("https://mopogotechnologies.com/uploadImages.php");
      final request = http.MultipartRequest('POST', url);
      request.fields['user_id'] = userId;
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final json = jsonDecode(resBody);

      if (json['status'] == 'success') {
        uploadedImageUrl = json['url'];

        print("Picked Image: ${_image?.path}");
        print("Upload URL: $uploadedImageUrl");
        print("User ID: $userId");

        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('courier').doc(userId).set(
            {'profilePictureUrl': uploadedImageUrl},
            SetOptions(merge: true),
          );
          print("Firestore update success");
        } catch (e) {
          print("Firestore error: $e");
        }

        setState(() {
          _isUploading = false;
        });

        showCustomToast("Profile updated successfully!");
      } else {
        setState(() {
          _isUploading = false;
        });
        showCustomToast(json['message'] ?? "Upload failed", isError: true);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      showCustomToast("An error occurred during upload", isError: true);
    }
  }

  Future<void> _getProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser!;
    final doc =
        await _firestore.collection('courier').doc(_currentUser.uid).get();

    setState(() {
      _isLoading =
          true; // Set loading state to true when model is being fetched
    });

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      print("Courier");
      print(data);

      setState(() {
        courierProfile = CourierProfileData.fromMap(data);
        // Now courierProfile is assigned safely
        name = courierProfile.name.toString();
        visas = courierProfile.visas ?? [];
        passports = courierProfile.passports ?? [];
        _nameController.text = courierProfile.name ?? 'N/A';
        _phoneController.text = courierProfile.phoneNumber ?? 'N/A';
        _hasCar = courierProfile.hasCar ?? false;
        _hasDrivingLicence = courierProfile.hasDrivingLicence ?? false;
        _willingToDoFirstLastMile =
            courierProfile.willingToDoFirstLastMile ?? false;

        _isLoading = false; // Set loading state to false once model is fetched
      });
    }
  }

  Future<void> _updateFireStore() async {
    try {
      setState(() {
        _isLoading = false;
      });
      Map<String, dynamic> data = {}; // Dynamic map to add non-null values

      data['id'] = _currentUser.uid;
      data['car'] = _hasCar;
      data['drivingLicence'] = _hasDrivingLicence;
      data['firstLastMile'] = _willingToDoFirstLastMile;

      // Check if name is not null or empty
      if (_nameController.text.isNotEmpty) {
        data['name'] = _nameController.text;
      }

      // Check if email is not null
      if (_currentUser.email != null && _currentUser.email!.isNotEmpty) {
        data['email'] = _currentUser.email;
      }

      if (_phoneController.text.isNotEmpty) {
        data['phoneNumber'] = _phoneController.text.toString();
      }

      // Check if profile picture URL is not null
      if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty) {
        data['profilePictureUrl'] = _profilePictureUrl;
      }

      // Check if visas list is not null or empty
      if (visas.isNotEmpty) {
        data['visas'] = visas.map((visa) => visa.toMap()).toList();
      }

      // Check if passports list is not null or empty
      if (passports.isNotEmpty) {
        data['passports'] =
            passports.map((passport) => passport.toMap()).toList();
      }

      // Update Firestore only if there is valid model
      if (data.isNotEmpty) {
        // Using set with merge: true to replace or add model if it doesn't exist
        await _firestore
            .collection('courier')
            .doc(_currentUser.uid)
            .set(data, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        setState(() {
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid model to save!')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error saving profile');
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Widget _buildPhoneNumberField(
      TextEditingController controller, Function(String) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
      child: IntlPhoneField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        initialCountryCode: 'PK', // Default country
        onChanged: (phone) {
          onChanged(phone.completeNumber); // Callback to get full number
        },
      ),
    );
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = 'profile_pictures/${_currentUser.uid}.jpg';
      try {
        TaskSnapshot uploadTask = await _storage.ref(fileName).putFile(file);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          _profilePictureUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile picture uploaded successfully!')),
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

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: EdgeInsets.only(top: 20, left: 24, right: 24),
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          actionsPadding: EdgeInsets.only(bottom: 10, right: 10),
          title: Row(
            children: [
              Icon(
                visa != null || passport != null
                    ? Icons.edit_note
                    : Icons.add_circle_outline,
                color: Colors.blueAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  visa != null || passport != null ? 'Edit $type' : 'Add $type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: countryController,
                  decoration: InputDecoration(
                    hintText: 'Country',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Country is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: expiryController,
                  decoration: InputDecoration(
                    hintText: 'Expiry Date DD/MM/YYY',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Expiry Date is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  if (type == 'Visa') {
                    Visa newVisa = Visa(
                      countryName: countryController.text,
                      expiryDate: expiryController.text,
                    );
                    if (visa != null) {
                      visas.remove(visa);
                    }
                    setState(() {
                      visas.add(newVisa);
                    });
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
                    setState(() {
                      passports.add(newPassport);
                    });
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: EdgeInsets.only(top: 20, left: 24, right: 24),
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          actionsPadding: EdgeInsets.only(bottom: 10, right: 10),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delete $type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this $type?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cancel the action
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  if (type == 'Visa' && visa != null) {
                    visas.remove(visa);
                  } else if (type == 'Passport' && passport != null) {
                    passports.remove(passport);
                  }
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('$name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading // Show ProgressIndicator while loading
            ? Center(
                child: CircularProgressIndicator(), // Circular progress bar
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
// UI
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: (uploadedImageUrl?.isNotEmpty == true)
                              ? CachedNetworkImageProvider(
                            "${uploadedImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}",
                          )
                              : (courierProfile.profilePictureUrl?.isNotEmpty == true)
                              ? CachedNetworkImageProvider(
                            "${courierProfile.profilePictureUrl!}?t=${DateTime.now().millisecondsSinceEpoch}",
                          )
                              : const AssetImage('assets/avatar.png') as ImageProvider,
                        ),

                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: InkWell(
                            onTap: pickImageAndUpload,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

/*              const SizedBox(height: 20),
              _buildProfileField('ID', courierProfile.id.toString()),*/
                    const SizedBox(height: 10),
                    _buildNonEditableField(
                        'Email:', _currentUser.email ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildEditableField('Name', _nameController),
                    const SizedBox(height: 10),
                    _buildPhoneNumberField(_phoneController, (phone) {
                      setState(() {
                        _selectedPhoneNumber = phone;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildVisaList(),
                    const SizedBox(height: 20),
                    _buildPassportList(),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Own Car?',
                                    style: TextStyle(fontSize: 16)),
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
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Driving Licence?',
                                    style: TextStyle(fontSize: 16)),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Willing to do mile?',
                                    style: TextStyle(fontSize: 16)),
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
                    const SizedBox(height: 30), // Add spacing before the button
                    // Save Button at the bottom
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        height: 50, // Height of the button
                        decoration: BoxDecoration(
                          color: Colors.blue, // Blue background
                          borderRadius:
                              BorderRadius.circular(8), // Rounded corners
                        ),
                        child: TextButton(
                          onPressed:
                              _updateFireStore, // Add your save profile method
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
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
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
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
        const Text('Visas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(type: 'Visa', visa: visa),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () =>
                        _showDeleteConfirmation(type: 'Visa', visa: visa),
                  ),
                ],
              ),
            );
          },
        ),
        ElevatedButton.icon(
          onPressed: () => _showEditDialog(type: 'Visa'),
          icon: const Icon(
            Icons.add,
            color: Colors.white, // Set the icon color to white
          ),
          label: const Text(
            'Add Visa',
            style:
                TextStyle(color: Colors.white), // Set the text color to white
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Set the background color to blue
            minimumSize: const Size(150, 40), // Set fixed width and height
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  10), // Set rounded corners with a radius
            ),
          ),
        ),
      ],
    );
  }

// Builds the list of passports and displays the expiry date with a date picker
  Widget _buildPassportList() {
    return Column(
      children: [
        const Text(
          'Passports',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: passports.length,
          itemBuilder: (context, index) {
            final passport = passports[index];
            return ListTile(
              title: Text(passport.countryName),
              subtitle: GestureDetector(
                onTap: () async {
                  // Open DatePicker when the expiry date is tapped
                  DateTime? selectedDate =
                      await _selectExpiryDate(context, passport.expiryDate);
                  if (selectedDate != null) {
                    setState(() {
                      passport.expiryDate = selectedDate
                          .toString()
                          .split(' ')[0]; // Update expiry date
                    });
                  }
                },
                child: Text('Expiry: ${passport.expiryDate}'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () =>
                        _showEditDialog(type: 'Passport', passport: passport),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(
                        type: 'Passport', passport: passport),
                  ),
                ],
              ),
            );
          },
        ),
        ElevatedButton.icon(
          onPressed: () => _showEditDialog(type: 'Passport'),
          icon: const Icon(
            Icons.add,
            color: Colors.white, // Set the icon color to white
          ),
          label: const Text(
            'Add Passport',
            style:
                TextStyle(color: Colors.white), // Set the text color to white
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Set the background color to blue
            minimumSize: const Size(60, 40), // Set fixed width and height
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  10), // Set rounded corners with a radius
            ),
          ),
        ),
      ],
    );
  }

// Function to show the date picker and disable previous dates
  Future<DateTime?> _selectExpiryDate(
      BuildContext context, String currentExpiryDate) async {
    DateTime initialDate = currentExpiryDate.isNotEmpty
        ? DateTime.parse(currentExpiryDate)
        : DateTime.now(); // Default to current date if no expiry date

    DateTime firstDate = DateTime.now(); // Disable dates before today
    DateTime lastDate = DateTime(2101); // Allow dates up to the year 2101

    // Show the date picker dialog
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    return pickedDate;
  }

  Widget _buildNonEditableField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
      decoration: BoxDecoration(
        color: Colors.white, // Light dark background
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),

          // Value + Lock icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.lock,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
