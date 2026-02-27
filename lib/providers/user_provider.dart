import 'package:diet_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diet_app/firebase/auth_service.dart';
import 'package:diet_app/firebase/db_service.dart';

class UserIdProvider with ChangeNotifier {
  final DBService _dbService = DBService();
  final Authentication _authentication = Authentication();

  String? uid;
  String? _userRole;
  String? _email;
  String? _fcmToken;

  Future<void> setUser(
      {required String id,
      required BuildContext context,
      required void Function() loadingFalse}) async {
    final CartProvider cartProvider = Provider.of(context, listen: false);
    uid = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userdata = await _dbService.getUser(id);
      _userRole = userdata['role'] ?? '';
      _email = userdata['email'];
      _fcmToken = userdata['fcmToken'] ?? '';
      // Save authentication state in SharedPreferences
      await prefs.setString('uid', id);
      await prefs.setString('userRole', _userRole!);
      await prefs.setString('email', _email!);
      await prefs.setString('fcmToken', _fcmToken!);
      cartProvider.clearCart();

      notifyListeners();
    } catch (error) {
      print("Error fetching user data: $error");
    } finally {
      loadingFalse();
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('uid')) {
      return false;
    }

    uid = prefs.getString('uid');

    if (uid == null || uid!.isEmpty) {
      await logout();
      return false;
    }

    final userData = await _dbService.getUser(uid!);

    // Check if the userData is null or empty
    if (userData == null || userData.isEmpty) {
      await logout();
      return false;
    }

    _userRole = prefs.getString('userRole');
    _email = prefs.getString('email');
    _fcmToken = prefs.getString('fcmToken');

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      if (uid != null || uid!.isNotEmpty) {
        await _dbService.emptyFmcToken(uid!);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _authentication.signOut();
      uid = null;
      _userRole = null;
      _email = null;
      _fcmToken = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  String? get getUuid => uid.toString();
  String? get getRole => _userRole.toString();
  String? get getEmail => _email.toString();
  String? get getFcmToken => _fcmToken.toString();

  Future<void> setEmail(
      {required String email, required String customerId}) async {
    await _authentication.updateEmail(email);
    notifyListeners();
  }
}
