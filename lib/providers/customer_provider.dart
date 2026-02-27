import 'package:diet_app/firebase/db_service.dart';
import 'package:flutter/material.dart';

class CustomerProvider with ChangeNotifier {
  String? _address;
  List<dynamic>? _allergies;
  String? _firstName;
  String? _lastName;
  String? _phone;
  String? _profilePicture;
  int? _weight;
  int? _age;
  double? _height;
  bool? _remindMeLater;
  String? _fcmToken;

  final DBService _dbService = DBService();

  void setCustomerData(
      {required String? address,
      required int? age,
      required List<dynamic>? allergies,
      required String firstName,
      required String lastName,
      required String phone,
      required String? profilePicture,
      required int? weight,
      required String? fcmToken,
      required double? height}) {
    _address = address;
    _age = age;
    _allergies = allergies;
    _firstName = firstName;
    _lastName = lastName;
    _phone = phone;
    _profilePicture = profilePicture;
    _weight = weight;
    _height = height;
    _fcmToken = fcmToken;
    _allergies = allergies;
    notifyListeners();
  }

  Future<void> setName(
      {required String firstName,
      required String lastName,
      required String customerId}) async {
    await _dbService.updateName(
        firstName: firstName, lastName: lastName, customerId: customerId);
    _firstName = firstName;
    _lastName = lastName;
    notifyListeners();
  }

  Future<void> setAllergies(
      {required List<String> selectedAllergies,
      required String customerId}) async {
    print("Setting allergies: $selectedAllergies");
    _allergies?.clear();
    _allergies?.addAll(selectedAllergies);
    await _dbService.updateAlergies(
        allergies: selectedAllergies, customerId: customerId);
    notifyListeners();
  }

  setPhone({required String phone, required String customerId}) async {
    await _dbService.updatePhone(phone: phone, customerId: customerId);
    _phone = phone;
    notifyListeners();
  }

  String? get getAddress => _address;
  int? get getAge => _age;
  List<dynamic>? get getAllergies => _allergies;
  String? get getFirstName => _firstName;
  String? get getLastName => _lastName;
  String? get getPhone => _phone;
  String? get getProfilePicture => _profilePicture;
  int? get getWeight => _weight;
  double? get getHeight => _height;
  String? get getFcmToken => _fcmToken;

  bool get customerHasData =>
      _age != 0 && _weight != 0 && _height != 0.0 && _address != null;

  bool get getCustomerHasAlergies => _allergies!.isNotEmpty;

  bool? get remindMeLater => _remindMeLater;

  get getUuid => null;

  void setRemindeMeLater() => {_remindMeLater = true, notifyListeners()};

  Future<void> setPhysicalInformation(
      {required int age,
      required double height,
      required int weight,
      required String customerId}) async {
    await _dbService.updatePhysicalInformation(
        age: age, height: height, weight: weight, customerId: customerId);
    _age = age;
    _height = height;
    _weight = weight;
    notifyListeners();
  }

  void setAddress({required String address}) {
    _address = address;
    notifyListeners();
  }

  Future<void> updateAddress(
      {required String address, required String customerID}) async {
    await _dbService.updateAddress(address: address, customerID: customerID);
    _address = address;
    notifyListeners();
  }

  Future<void> updateProfilePicturePathToDB(
      String imageUrl, String customerId) async {
    try {
      await _dbService.updateCustomerProfilePicture(
          customerId: customerId, imageUrl: imageUrl);

      _profilePicture = imageUrl;
      notifyListeners();
    } catch (e) {
      print('Error updating profile picture: $e');
      rethrow;
    }
  }

  double calculateBmi() {
    if (_weight == 0 || _height == 0) {
      return 0;
    }
    double heightInMeter = _height! / 100;
    double bmi = _weight! / (heightInMeter * heightInMeter);
    return bmi;
  }
}
