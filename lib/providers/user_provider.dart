import 'dart:async';
import 'dart:developer' as developer;
import 'package:diet_app/providers/cart_provider.dart';
import 'package:diet_app/firebase/quota_guard.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/quota_limit_notifier.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diet_app/firebase/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserIdProvider with ChangeNotifier {
  final DBService _dbService = DBService();
  final Authentication _authentication = Authentication();

  String? uid;
  String? _userRole;
  String? _email;
  String? _fcmToken;
  bool _isLoggingOut = false;

  // DO NOT add custom auto-login logic.
  // DO NOT restore session from local storage.
  // FirebaseAuth is the only source of truth for auth state.

  Future<void> setUser(
      {required String id,
      required BuildContext context,
      required void Function() loadingFalse}) async {
    final CartProvider cartProvider = Provider.of(context, listen: false);
    uid = id;
    try {
      developer.log('📋 SETUSER_START: uid=$id');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Step 1: Read user document ONCE
      developer.log('📖 SETUSER_READ_USER_DOC: uid=$id');
      dynamic userdata = await _dbService.getUser(id);
      
      if (userdata == null || userdata is! Map) {
        developer.log('⚠️  SETUSER_USER_DATA_EMPTY: uid=$id, using local fallback');
        userdata = <String, dynamic>{};
      }
      
      // Step 2: Extract core data (no writes)
      final roleValue = userdata['role']?.toString().trim() ?? '';
      final emailValue = userdata['email']?.toString().trim().isNotEmpty == true
          ? userdata['email']?.toString().trim() ?? ''
          : (FirebaseAuth.instance.currentUser?.email ?? '');
      final fcmTokenValue = userdata['fcmToken']?.toString().trim() ?? '';
      
      _userRole = roleValue;
      _email = emailValue;
      _fcmToken = fcmTokenValue;
      
      developer.log('✅ SETUSER_DATA_LOADED: uid=$id, role=$_userRole, email=$_email');

      // Keep login read-only: use local fallback role and avoid Firestore writes.
      final role = roleValue.isNotEmpty ? roleValue : 'customer';
      _userRole = role;
      developer.log('✅ SETUSER_ROLE_RESOLVED_LOCAL: uid=$id, role=$_userRole');

      if (_userRole == null || _userRole!.isEmpty) {
        throw 'User role is missing. Please contact support.';
      }
      
      // Step 4: Save to local cache (no Firebase write)
      developer.log('💾 SETUSER_CACHE_LOCAL: uid=$id');
      await prefs.setString('uid', id);
      await prefs.setString('userRole', _userRole ?? '');
      await prefs.setString('email', _email ?? '');
      await prefs.setString('fcmToken', _fcmToken ?? '');
      cartProvider.clearCart();

      developer.log('✅ SETUSER_COMPLETE: uid=$id, role=$_userRole, writes=0');
      notifyListeners();
    } catch (error) {
      developer.log('❌ SETUSER_ERROR: uid=$uid, error=$error');
      QuotaGuard.instance.markIfQuotaExceeded(
        error,
        operation: 'setUser',
      );
      if (context.mounted) {
        await QuotaLimitNotifier.showIfNeeded(context);
      }
      FlutterToast.showToast(
          error.toString(), DefaultColors().redColor);
      debugPrint("Error fetching user data: $error");
      rethrow;
    } finally {
      loadingFalse();
    }
  }

  Future<void> logout() async {
    if (_isLoggingOut) {
      developer.log('⏭️  LOGOUT_ALREADY_RUNNING');
      return;
    }

    _isLoggingOut = true;
    final cachedUid = uid;
    developer.log('🔐 LOGOUT_START: uid=$cachedUid');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logout_in_progress', true);
      developer.log('✅ LOGOUT_MARKER_SET: uid=$cachedUid');
    } catch (e) {
      developer.log('⚠️  LOGOUT_MARKER_SET_IGNORED: uid=$cachedUid, error=$e');
    }

    try {
      try {
        await _authentication
            .signOut()
            .timeout(const Duration(seconds: 5));
        developer.log('✅ LOGOUT_AUTH_DONE: uid=$cachedUid');
      } on TimeoutException catch (_) {
        developer.log('⚠️  SIGNOUT_TIMEOUT: uid=$cachedUid');
      }
    } catch (e) {
      developer.log('⚠️  LOGOUT_AUTH_ERROR_IGNORED: uid=$cachedUid, error=$e');
    }

    reset();
    developer.log('✅ LOGOUT_LOCAL_STATE_CLEARED: uid=$cachedUid');

    Future(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await prefs.remove('logout_in_progress');
        developer.log('✅ LOGOUT_SESSION_CLEARED: uid=$cachedUid');
      } catch (e) {
        developer.log('⚠️  LOGOUT_SESSION_CLEAR_IGNORED: uid=$cachedUid, error=$e');
      } finally {
        _isLoggingOut = false;
      }
    });

    if (cachedUid != null && cachedUid.isNotEmpty && !QuotaGuard.instance.quotaExceeded) {
      Future(() async {
        try {
          developer.log('📝 LOGOUT_CLEAR_FCM: uid=$cachedUid');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcmToken', '');
          developer.log('✅ LOGOUT_CLEAR_FCM_DONE: uid=$cachedUid');
        } catch (e) {
          developer.log('⚠️  LOGOUT_CLEAR_FCM_IGNORED: uid=$cachedUid, error=$e');
        }
      });
    } else {
      developer.log('⏭️  LOGOUT_CLEANUP_SKIPPED: uid=$cachedUid, reason=${QuotaGuard.instance.quotaExceeded ? 'quota' : 'no_uid'}');
    }

    developer.log('✅ LOGOUT_COMPLETE: uid=$cachedUid');
  }

  bool get isLoggingOut => _isLoggingOut;

  void setUid(String userId) {
    final changed = uid != userId;
    uid = userId;
    if (changed) notifyListeners();
  }

  void syncAuthUser(String userId) => setUid(userId);

  void reset() {
    uid = null;
    _userRole = null;
    _email = null;
    _fcmToken = null;
    notifyListeners();
  }

  String? get getUuid => uid;
  String? get getRole => _userRole;
  String? get getEmail => _email;
  String? get getFcmToken => _fcmToken;

  Future<void> setEmail(
      {required String email, required String customerId}) async {
    await _authentication.updateEmail(email);
    notifyListeners();
  }
}
