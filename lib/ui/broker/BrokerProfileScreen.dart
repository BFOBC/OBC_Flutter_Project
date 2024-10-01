import 'package:broker_flutter_pp/ui/broker/data/BrokerProfileData.dart';
import 'package:flutter/material.dart';

class BrokerProfileScreen extends StatefulWidget {
  final BrokerProfileData profile;

  const BrokerProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  _BrokerProfileScreenState createState() => _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends State<BrokerProfileScreen> {
  List<TextEditingController> _licenseControllers = [];
  final TextEditingController _paymentTermsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with existing licenses and profile information
    _licenseControllers = widget.profile.license
        .map((license) => TextEditingController(text: license))
        .toList();
    _paymentTermsController.text = widget.profile.paymentTerms;
  }

  @override
  void dispose() {
    // Dispose of all controllers when the widget is disposed
    for (var controller in _licenseControllers) {
      controller.dispose();
    }
    _paymentTermsController.dispose();
    super.dispose();
  }

  // Adds a new license text field
  void _addLicenseField() {
    setState(() {
      _licenseControllers.add(TextEditingController());
    });
  }

  // Removes a specific license field
  void _removeLicenseField(int index) {
    setState(() {
      _licenseControllers.removeAt(index);
      if (_licenseControllers.isEmpty) {
        _addLicenseField(); // Add a new empty field if all are removed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Set a light background
      appBar: AppBar(
        title: const Text('Broker Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular avatar centered at the top
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/avatar.png'), // Replace with your asset
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // Action for edit (optional)
                        },
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

                // Profile Information in rounded containers with white backgrounds
                _buildProfileField('ID', widget.profile.id),
                const SizedBox(height: 10),
                _buildProfileField('Name', widget.profile.name),
                const SizedBox(height: 10),
                _buildNonEditableField('Email', widget.profile.email), // Email non-editable
                const SizedBox(height: 10),
                _buildProfileField('Website', widget.profile.website),
                const SizedBox(height: 10),
                _buildProfileField('Country', widget.profile.country),
                const SizedBox(height: 10),

                // Editable field for Payment Terms with margin
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: _buildEditableField('Payment Terms', _paymentTermsController),
                ),

                const SizedBox(height: 10),

                // License List in one card
                _buildLicenseCard(),
                const SizedBox(height: 20),

                // Save button at the end
                ElevatedButton(
                  onPressed: () {
                    // Add your save logic here
                    print("Saving profile...");
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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

  // Helper widget for editable fields
  Widget _buildEditableField(String label, TextEditingController controller) {
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
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                hintText: 'Enter $label',
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modified License List - all licenses in one card
  Widget _buildLicenseCard() {
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
          // Display licenses in one container
          for (int i = 0; i < _licenseControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _licenseControllers[i],
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Enter License',
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
          TextButton(
            onPressed: _addLicenseField,
            child: const Text('Add License'),
          ),
        ],
      ),
    );
  }
}
