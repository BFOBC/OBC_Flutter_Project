import 'package:firebase_auth/firebase_auth.dart';

class AuthUtils {
  // Static method to get the current logged-in user's ID (Asynchronous)
  static Future<String?> getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;  // Return the user ID if logged in, otherwise null
  }
  static String? getCurrentUserId2()  {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;  // Return the user ID if logged in, otherwise null
  }
}
