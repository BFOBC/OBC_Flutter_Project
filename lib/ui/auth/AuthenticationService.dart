import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signIn({required String email, required String password}) async {
    try {
      // Use signInWithEmailAndPassword to authenticate the user
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

      // Directly access the current user after authentication
      User? currentUser = _firebaseAuth.currentUser;
      print('Current User: $currentUser'); // Log the user object

      return currentUser; // Return the current user
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  

  // Sign up with email and password
  Future<User?> signUp({required String email, required String password}) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Check if user is logged in
  Stream<User?> get userChanges => _firebaseAuth.authStateChanges();
}
