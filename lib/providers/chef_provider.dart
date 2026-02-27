import 'package:diet_app/firebase/db_service.dart';
import 'package:flutter/foundation.dart';

import 'package:image_picker/image_picker.dart';

class CheffProvider with ChangeNotifier {
  final DBService dbService = DBService();

  String? _phoneNumber;
  String? _kitchenName;
  String? _address;
  String? _profilePicture;

  void setCheff({
    required String phoneNumber,
    required String kitchenName,
    required String? address,
    required String? profilePicture,
  }) {
    _phoneNumber = phoneNumber;
    _kitchenName = kitchenName;
    _address = address;
    _profilePicture = profilePicture;
    notifyListeners();
  }

  String? get getKitchenName => _kitchenName;
  String? get getPhoneNumber => _phoneNumber;
  String? get getAddress => _address;
  String? get getProfilePicture => _profilePicture;

  bool get chefHasAddress => _address != null;

  Future<void> setKitchenName({
    required String kitchenName,
    required String cheffId,
  }) async {
    final response = await dbService.updateChefName(
      kitchenName: kitchenName,
      cheffId: cheffId,
    );
    if (response) {
      _kitchenName = kitchenName;
      notifyListeners();
    }
  }

  Future<void> setPhoneNumber({
    required String phone,
    required String cheffId,
  }) async {
    final response = await dbService.updateChefPhone(
      phone: phone,
      cheffId: cheffId,
    );
    if (response) {
      _phoneNumber = phone;
      notifyListeners();
    }
  }

  void setAddress(String address) {
    _address = address;
    notifyListeners();
  }

  Future<void> updateAddress(
      {required String address, required String chefId}) async {
    final response =
        await dbService.updateChefAddress(address: address, chefId: chefId);

    if (response) {
      _address = address;
      notifyListeners();
    }
  }

  Future<void> updateProfilePicture({
    required String imageUrl,
    required String cheffId,
  }) async {
    try {
      await dbService.updateChefProfilePicture(
        cheffId: cheffId,
        imageUrl: imageUrl,
      );
      _profilePicture = imageUrl;
      notifyListeners();
    } catch (e) {
      print('Error updating chef profile picture: $e');
      rethrow;
    }
  }

  Future<String> uploadAndUpdateMealPicture({
    required XFile imageFile,
    required String cheffId,
    required String mealId,
  }) async {
    try {
      print('Uploading meal picture...');
      String downloadURL =
          await dbService.uploadMealPicture(imageFile, cheffId);
      await dbService.updateMealPicture(mealId: mealId, imageUrl: downloadURL);

      notifyListeners();
      return downloadURL;
    } catch (e) {
      print('Error uploading and updating meal picture: $e');
      rethrow;
    }
  }

  Future<void> updateProfilePicturePathToDB(
      String imageUrl, String customerId) async {
    try {
      await dbService.updateCheffProfilePicture(
          cheffId: customerId, imageUrl: imageUrl);
      print('Image URL::::::::::::::::::::::::::::::: $imageUrl');
      _profilePicture = imageUrl;
      notifyListeners();
    } catch (e) {
      print('Error updating profile picture: $e');
      rethrow;
    }
  }
}
