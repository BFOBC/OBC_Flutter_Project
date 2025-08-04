import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  @override
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool locationGranted = false;
  bool mediaGranted = false;
  bool notificationGranted = false;

  Future<void> checkPermissions() async {
    final locStatus = await Permission.location.status;
    final camStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    final notificationStatus = await Permission.notification.status;

    setState(() {
      locationGranted = locStatus.isGranted;
      mediaGranted = camStatus.isGranted && photosStatus.isGranted;
      notificationGranted = notificationStatus.isGranted;
    });
  }

  Future<void> requestPermissions() async {
    final locStatus = await Permission.location.request();
    final camStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();
    final notifStatus = await Permission.notification.request();

    setState(() {
      locationGranted = locStatus.isGranted;
      mediaGranted = camStatus.isGranted && photosStatus.isGranted;
      notificationGranted = notifStatus.isGranted;
    });

    if (locationGranted && mediaGranted && notificationGranted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NextScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please grant all permissions to proceed."),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  Widget permissionTile(String title, bool granted) {
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle : Icons.info,
        color: granted ? Colors.green : Colors.orange,
      ),
      title: Text(title),
      subtitle: Text(granted ? 'Permission granted' : 'Permission needed'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Permissions Required')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'This app needs the following permissions to run:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            permissionTile('Location', locationGranted),
            permissionTile('Camera / Photos', mediaGranted),
            permissionTile('Notifications', notificationGranted),
            Spacer(),
            ElevatedButton(
              onPressed: requestPermissions,
              child: Text('Grant Permissions & Continue'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NextScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('✅ All permissions granted! Welcome to the app.')),
    );
  }
}
