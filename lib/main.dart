
import 'package:broker_flutter_pp/ui/common/screens/DataSyncScreen.dart';
import 'package:broker_flutter_pp/ui/common/viewmodels/TaskViewModel.dart';
import 'package:broker_flutter_pp/ui/common/screens/SplashScreen.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures binding is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.requestPermission(); // Important for iOS

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true); // For testing, set to false in prod
  Workmanager().registerPeriodicTask(
    "deleteExpiredRecordsTask",
    "checkAndDeleteExpiredDocuments",
    frequency: const Duration(minutes: 15), // Minimum allowed
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()), // Initialize RoleProvider
        ChangeNotifierProvider(create: (context) => TaskViewModel()), // Initialize TaskViewModel
      ],
      child: const MyApp(),
    ),
  );
}
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();

    final now = DateTime.now().toUtc();
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore.collection('emptyLegs').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final toDateTimeStr = data['toDateTime'];

      if (toDateTimeStr != null) {
        final toDateTime = DateTime.tryParse(toDateTimeStr);
        if (toDateTime != null && toDateTime.isBefore(now)) {
          await firestore.collection('emptyLegs').doc(doc.id).delete();
          print('🔥 Deleted expired document: ${doc.id}');
        }
      }
    }

    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 👈 Add this line
      title: 'OBC App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}
