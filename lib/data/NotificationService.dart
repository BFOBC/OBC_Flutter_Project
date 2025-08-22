import 'dart:convert';
import 'package:broker_flutter_pp/ui/broker/mission/BrokerMissions.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:broker_flutter_pp/ui/chat/ChatListScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:broker_flutter_pp/ui/courier/missions/CompleteMilestone.dart';
import 'package:broker_flutter_pp/ui/courier/missions/CourierMissions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../ui/common/utils/RoleProvider.dart';

// Aur main.dart ka import karo
import 'package:broker_flutter_pp/main.dart';

//final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static const String _serverUrl =
      "https://mopogotechnologies.com/fcm-server/send_notification.php";
  static String? currentRoute;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Map screen names from notification data → actual Widget
/*  static final Map<String, Widget Function()> screenRoutes = {
    "DrawerScreen": () => DrawerScreen(),
    "CourierMissions": () => CourierMissions(),
    "BrokerMissionScreen": () => BrokerMissions(),
    "ChatDetailScreen": () => ChatDetailScreen(
          userID: 'VmM650tiV1WqZGnQW3rujDG4FOB2',
        ), // add this
    // Add more here as needed
  };*/

  /// Init service
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          final data = jsonDecode(details.payload!);
          _handleNotificationClick(data);
        }
      },
    );

    // Request notification permissions
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("📩 Foreground message: ${message.data}");

      // Sirf login user ke liye check
      if (await _shouldShowNotification(message.data)) {
        final title =
            message.notification?.title ?? message.data['title'] ?? '';
        final body = message.notification?.body ?? message.data['body'] ?? '';

        await _showLocalNotification(
          title: title,
          body: body,
          payload: jsonEncode(message.data),
        );
      } else {
        print("ℹ️ Notification skipped (user not logged in or token mismatch)");
      }
    });
    // Background → app open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📩 Opened from background: ${message.data}");
      _handleNotificationClick(message.data);
    });

    // Terminated → app open
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print("📩 Opened from terminated: ${initialMessage.data}");
      _handleNotificationClick(initialMessage.data);
    }
  }

  /// Handle navigation dynamically
  static final Map<String, Widget Function(Map<String, dynamic> data)> screenRoutes = {
    "DrawerScreen": (data) => DrawerScreen(),
    "CourierMissions": (data) => CourierMissions(),
    "BrokerMissionScreen": (data) => BrokerMissions(),
    "ChatDetailScreen": (data) => ChatDetailScreen(
      userID: data['userID'] ?? 'defaultUser',
    ),
    // Add more screens here
  };

  static void _handleNotificationClick(Map<String, dynamic> data) {
    final screen = data['screen'];
    print("🔀 Navigate to: $screen");

    if (screen != null && screenRoutes.containsKey(screen)) {
      final nav = navigatorKeyMain.currentState;

      if (nav == null) {
        print("⚠️ Navigator not ready, skipping");
        return;
      }

      // App terminated → always reset to DrawerScreen, then push screen
      if (FirebaseMessaging.instance.getInitialMessage() != null) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DrawerScreen()),
              (route) => false,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          nav.push(
            MaterialPageRoute(builder: (_) => screenRoutes[screen]!(data)),
          );
        });
        return;
      }

      // App already running (foreground/background) → just push new screen
      if (currentRoute == screen) {
        print("⚠️ Already on $screen, no navigation");
        return;
      }
      currentRoute = screen;

      nav.push(
        MaterialPageRoute(builder: (_) => screenRoutes[screen]!(data)),
      );
    } else {
      print("⚠️ No matching screen found for: $screen");
    }
  }




  static Future<bool> _shouldShowNotification(Map<String, dynamic> data) async {
    // Always return true for testing
    print("🔹 _shouldShowNotification called");
    return true;
  }

  /// Get logged-in user's FCM token & name
  static Future<Map<String, String?>?> getUserFcmInfo(context) async {
    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      String collectionName =
          roleProvider.role == UserRole.broker ? 'broker' : 'courier';

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "token": data['fcm_token'] as String?,
          "name": data['name'] as String?,
        };
      }
      return null;
    } catch (e) {
      print("❌ Error fetching FCM info: $e");
      return null;
    }
  }
  /// Get Courier Name & FCM Token
  static Future<Map<String, String?>?> getCourierNameAndTokenById(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courier')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "name": data['name'] as String?,
          "token": data['fcm_token'] as String?,
        };
      }
      return null;
    } catch (e) {
      print("❌ Error fetching Courier Name & Token for userID $userId: $e");
      return null;
    }
  }
  static Future<Map<String, String?>?> getBrokerNameAndTokenById(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('broker')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "name": data['name'] as String?,
          "token": data['fcm_token'] as String?,
        };
      }
      return null;
    } catch (e) {
      print("❌ Error fetching Courier Name & Token for userID $userId: $e");
      return null;
    }
  }

  /// Get opposite role user's FCM token
  static Future<String?> getUserFcmTokenById(String userId) async {
    try {
      // Check in broker collection
      var doc = await FirebaseFirestore.instance
          .collection('broker')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcm_token'] as String?;
      }

      // Check in courier collection
      doc = await FirebaseFirestore.instance
          .collection('courier')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcm_token'] as String?;
      }

      return null; // userID kisi bhi collection me nahi mila
    } catch (e) {
      print("❌ Error fetching FCM token for userID $userId: $e");
      return null;
    }
  }

  /// Send notification with dynamic screen
  static Future<bool> sendNotification({
    required String title,
    required String toToken,
    required String type,
    required String screen,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final Map<String, String> templates = {
        "broker_request": "{name} has sent you a job request.",
        "courier_accept": "{name} has accepted your request.",
        "courier_reject": "{name} has rejected your request.",
        "job_completed": "{name} has marked the job as completed.",
        "decline_job": "{name} has decline your Job",
        "accepted_job": "{name} has accepted your Job",
        "job_started": "{name} has started the Job",
        "mile_stone_completed": "{name} has completed a milestone.",
        "new_msg": "{name} has sent you a message",
      };

      if (!templates.containsKey(type)) {
        throw Exception("Invalid notification type: $type");
      }

      final senderName = extraData?["senderName"] ?? "Someone";
      final body = templates[type]!.replaceAll("{name}", senderName);

      final mergedData = {
        "screen": screen, // screen comes from caller
        ...?extraData,
      };

      final response = await http.post(
        Uri.parse(_serverUrl),
        body: {
          "token": toToken,
          "title": title,
          "body": body,
          "data": jsonEncode(mergedData),
        },
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent: $type → $screen");
        return true;
      } else {
        print("❌ Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error sending notification: $e");
      return false;
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
