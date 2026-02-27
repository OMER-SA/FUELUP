import 'package:diet_app/components/auth/signup_emailverficiation_dialog.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/firebase/firebase_messaging.dart';
import 'package:diet_app/modals/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Authentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DBService _dbService = DBService();
  final FirebaseNotificationService messagingService =
      FirebaseNotificationService();
  

  Future<String?> register(SingUpDto userData, context) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: userData.email,
        password: userData.password,
      );
      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await emailVerficiationDialog(
            context, 'Verification email sent to ${user.email}', user);
      }
      await user?.reload();

      while (!user!.emailVerified) {
        await user.reload();
        user = _auth.currentUser;
        await Future.delayed(Duration(seconds: 2));
      }
      if (user.emailVerified) {
        await _dbService.storeUserData(user, userData, 'fcmToken');
        await messagingService.initialize(userID: user.uid.toString());
        return user.uid;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await messagingService.initialize(
          userID: userCredential.user!.uid.toString());

      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      print("Error while logging in: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return email;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      // Registration exceptions
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';

      // Login exceptions
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';

      // General exceptions
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'network-request-failed':
        return 'Network request failed. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in.';
      }
      await user.verifyBeforeUpdateEmail(newEmail);
      await user.updateEmail(newEmail);

      print("Verification email sent to $newEmail");
      return;
    } on FirebaseAuthException catch (e) {
      print("Error updating email: $e");
      throw _handleFirebaseAuthException(e);
    }
  }
}
