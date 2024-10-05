// File generated manually based on the provided Firebase JSON file.
// This file configures Firebase for Android (and iOS, if needed).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('FirebaseOptions have not been configured for Web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios; // You can update this if you add iOS configuration
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'FirebaseOptions have not been configured for macOS - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'FirebaseOptions have not been configured for Windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseOptions have not been configured for Linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJhcirGyQXqELNC5s1fcKcS9a5nVBK5EE',  // From your JSON
    appId: '1:155217089865:android:d678dbd733983609507698',  // From your JSON
    messagingSenderId: '155217089865',  // From your JSON
    projectId: 'obcflutter',  // From your JSON
    storageBucket: 'obcflutter.appspot.com',  // From your JSON
    databaseURL: 'https://obcflutter-default-rtdb.firebaseio.com',  // Real-time database URL
  );

  static const FirebaseOptions ios = FirebaseOptions(
    // Placeholder - update with your iOS configuration when available
    apiKey: 'your-ios-api-key',
    appId: 'your-ios-app-id',
    messagingSenderId: 'your-ios-messaging-id',
    projectId: 'obcflutter',
    storageBucket: 'obcflutter.appspot.com',
  );
}
