import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
      final fileName =
          '${mealId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'meal_pictures/$fileName';
      final ref = _storage.ref(filePath);

      developer.log('UPLOAD_START: path=${ref.fullPath}');

      // Capture the TaskSnapshot so getDownloadURL uses the ref that Firebase
      // actually wrote to — avoids no-object-found when Storage normalises paths.
      final snapshot = await ref.putFile(File(imageFile.path)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception(
            'Image upload timed out after 30 s — check network and Storage rules'),
      );

      developer.log('UPLOAD_COMPLETE: path=${snapshot.ref.fullPath}');

      final downloadURL = await snapshot.ref.getDownloadURL();

      developer.log('DOWNLOAD_URL_OBTAINED: url=$downloadURL');
      return downloadURL;
    } catch (e) {
      debugPrint('Error uploading meal picture: $e');
      rethrow;
    }
  }
}
