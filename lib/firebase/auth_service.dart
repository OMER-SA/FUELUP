import 'dart:developer' as developer;
import 'package:diet_app/components/auth/signup_emailverficiation_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/firebase/firebase_messaging.dart';
import 'package:diet_app/firebase/quota_guard.dart';
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
        email: userData.email.trim().toLowerCase(),
        password: userData.password,
      );
      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await emailVerficiationDialog(
            context, 'Verification email sent to ${user.email}', user);
      }
      await user?.reload();

      // Poll for email verification with timeout (max 5 minutes)
      const int maxRetries = 150;
      int retryCount = 0;
      while (!user!.emailVerified && retryCount < maxRetries) {
        await user.reload();
        user = _auth.currentUser;
        await Future.delayed(const Duration(seconds: 2));
        retryCount++;
      }

      if (!user.emailVerified) {
        throw 'Email verification timed out. Please verify your email and try logging in.';
      }

      if (user.emailVerified) {
        await _dbService.storeUserData(user, userData, 'fcmToken');
        if (!QuotaGuard.instance.quotaExceeded) {
          await messagingService.initialize(userID: user.uid.toString());
        } else {
          developer.log('REGISTER_POST_WRITE_SKIPPED_QUOTA: uid=${user.uid}');
        }
        return user.uid;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw 'Account created, but profile setup is blocked by Firestore permissions. Please contact support.';
      }
      throw 'Profile setup failed. Please try again.';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      developer.log('🔐 LOGIN_START: email=$email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = userCredential.user?.uid;
      developer.log('✅ LOGIN_AUTH_SUCCESS: uid=$uid, email=$email');

      // Keep login path read-only. Any write-capable setup is deferred outside auth.
      developer.log('LOGIN_POST_PROCESSING_READ_ONLY: uid=$uid');

      developer.log('✅ LOGIN_COMPLETE: uid=$uid');
      return uid;
    } on FirebaseAuthException catch (e) {
      final errorMsg = _handleFirebaseAuthException(e);
      developer.log('❌ LOGIN_AUTH_ERROR: code=${e.code}, msg=$errorMsg, email=$email');
      throw errorMsg;
    } catch (e) {
      developer.log('❌ LOGIN_UNEXPECTED_ERROR: error=$e, email=$email');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final currentUser = _auth.currentUser?.uid;
      developer.log('🔐 LOGOUT_START: uid=$currentUser');
      
      await _auth.signOut();
      
      developer.log('✅ LOGOUT_SUCCESS: uid=$currentUser');
    } catch (e) {
      developer.log('❌ LOGOUT_ERROR: error=$e');
      rethrow;
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

      debugPrint("Verification email sent to $newEmail");
      return;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error updating email: $e");
      throw _handleFirebaseAuthException(e);
    }
  }
}
