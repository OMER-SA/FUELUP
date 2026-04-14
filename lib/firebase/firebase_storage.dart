import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseDataStorage {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePicture(
      XFile imageFile, String customerId, String role) async {
    try {
      String fileName = '${role.trim()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String filePath = '${role.trim()}_/$fileName';

      await _storage.ref(filePath).putFile(File(imageFile.path));

      String downloadURL = await _storage.ref(filePath).getDownloadURL();

      return downloadURL;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  Future<String> uploadMealPicture(XFile imageFile, String mealId) async {
    try {
      String fileName =
          'meal_pictures/${mealId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String filePath = 'mealpuctures/$fileName';

      await _storage.ref(filePath).putFile(File(imageFile.path));

      String downloadURL = await _storage.ref(filePath).getDownloadURL();

      return downloadURL;
    } catch (e) {
      debugPrint('Error uploading meal picture: $e');
      rethrow;
    }
  }
}
