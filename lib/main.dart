
import 'package:broker_flutter_pp/ui/common/screens/DataSyncScreen.dart';
import 'package:broker_flutter_pp/ui/common/viewmodels/TaskViewModel.dart';
import 'package:broker_flutter_pp/ui/common/screens/SplashScreen.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  initializeWorkManager();

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
void initializeWorkManager() {
  // ✅ Initialize WorkManager
  Workmanager().initialize(
    callbackDispatcher, // use only one dispatcher
    isInDebugMode: false, // 👈 Disable debug logging + notification
  );
  // ✅ Register periodic task here
  Workmanager().registerPeriodicTask(
    'deleteExpiredRecordsTask',
    'checkAndDeleteExpiredDocuments',
    frequency: Duration(hours: 24), // 🔁 Daily cleanup
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: Duration(minutes: 5),
    initialDelay: Duration(minutes: 1),
  );
}
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();

      // ✅ Set up local notifications
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // ✅ Show persistent notification for foreground service
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'cleanup_foreground',
        'Cleanup Foreground',
        channelDescription: 'Runs background cleanup in foreground',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // keeps notification visible
        onlyAlertOnce: true,
      );

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      // 🔁 Show foreground-style notification
      await flutterLocalNotificationsPlugin.show(
        0,
        'OBC App',
        'Running cleanup task...',
        platformChannelSpecifics,
      );

      // 🔥 Perform the cleanup
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now().toUtc();
      final snapshot = await firestore.collection('emptyLegs').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final toDateTimeStr = data['toDateTime'];
        final toDateTime = DateTime.tryParse(toDateTimeStr ?? '');
        if (toDateTime != null && toDateTime.isBefore(now)) {
          await doc.reference.delete();
        }
      }

      // ✅ Dismiss notification after work is done
      await flutterLocalNotificationsPlugin.cancel(0);

      return Future.value(true);
    } catch (e, stack) {
      print('❌ Error in background task: $e');
      return Future.value(false);
    }
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
