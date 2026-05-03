import 'dart:async';

import 'package:diet_app/firebase/bmi_history_service.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/models/mood_types.dart';
import 'package:diet_app/utilities/tdee_calculator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerProvider with ChangeNotifier {
  CustomerProvider() {
    unawaited(loadPersistedMood());
  }

  // Returns the user's daily goal calories based on current state.
  double? get goalCalories {
    final weight = _weight?.toDouble();
    final height = _height;
    final age = _age;

    if (weight == null || height == null || age == null) return null;
    if (weight <= 0 || height <= 0 || age <= 0) return null;

    final calculatedGoalCalories = TdeeCalculator.calculateAll(
      weightKg: weight,
      heightCm: height,
      age: age,
      isMale: (_gender ?? 'male') == 'male',
      activityLevel: _activityLevel ?? 'moderate',
      targetWeight: _targetWeight,
    )['goalCalories'];

    if (calculatedGoalCalories == null ||
        !calculatedGoalCalories.isFinite ||
        calculatedGoalCalories <= 0) {
      return null;
    }

    return calculatedGoalCalories;
  }

  String? _address;
  List<String> _allergies = [];
  List<String> _dietaryPreferences = [];
  String? _firstName;
  String? _lastName;
  String? _phone;
  String? _profilePicture;
  int? _weight;
  int? _age;
  double? _height;
  bool? _remindMeLater;
  String? _fcmToken;
  double? _targetWeight;
  String? _activityLevel;
  String? _gender;
  String? _customerId;
  MoodType? _currentMood;
  double _moodConfidence = 0.0;
  MoodSource _moodSource = MoodSource.unknown;

  final DBService _dbService = DBService();
  final BmiHistoryService _bmiHistoryService = BmiHistoryService();

  void setCustomerData({
    required String? address,
    required int? age,
    required List<dynamic>? allergies,
    required String firstName,
    required String lastName,
    required String phone,
    required String? profilePicture,
    required int? weight,
    required String? fcmToken,
    required double? height,
    double? targetWeight,
    String? activityLevel,
    String? gender,
    String? customerId,
  }) {
    _address = address;
    _age = age;
    _allergies = _normalizeStringList(allergies);
    _firstName = firstName;
    _lastName = lastName;
    _phone = phone;
    _profilePicture = profilePicture;
    _weight = weight;
    _height = height;
    _fcmToken = fcmToken;
    _targetWeight = targetWeight;
    _activityLevel = activityLevel ?? 'moderate';
    _gender = gender ?? 'male';
    _customerId = customerId;
    notifyListeners();

    if ((_customerId ?? '').isNotEmpty) {
      loadUserPreferences();
    }
  }

  Future<void> setName({
    required String firstName,
    required String lastName,
    required String customerId,
  }) async {
    await _dbService.updateName(
      firstName: firstName,
      lastName: lastName,
      customerId: customerId,
    );
    _firstName = firstName;
    _lastName = lastName;
    notifyListeners();
  }

  Future<void> setAllergies({
    required List<String> selectedAllergies,
    required String customerId,
  }) async {
    debugPrint('Setting allergies: $selectedAllergies');
    _customerId = customerId;
    await saveAllergies(selectedAllergies);
  }

  setPhone({required String phone, required String customerId}) async {
    await _dbService.updatePhone(phone: phone, customerId: customerId);
    _phone = phone;
    notifyListeners();
  }

  String? get getAddress => _address;
  int? get getAge => _age;
  List<dynamic>? get getAllergies => _allergies;
  List<String> get allergies => List.unmodifiable(_allergies);
  String? get getFirstName => _firstName;
  String? get getLastName => _lastName;
  String? get getPhone => _phone;
  String? get getProfilePicture => _profilePicture;
  int? get getWeight => _weight;
  double? get getHeight => _height;
  String? get getFcmToken => _fcmToken;
  double? get getTargetWeight => _targetWeight;
  String get getActivityLevel => _activityLevel ?? 'moderate';
  String get getGender => _gender ?? 'male';
  MoodType? get currentMood => _currentMood;
  MoodType? get currentMoodType => _currentMood;
  double get moodConfidence => _moodConfidence;
  MoodSource get moodSource => _moodSource;
  List<String> get dietaryPreferences => List.unmodifiable(_dietaryPreferences);

  bool get customerHasData =>
      _age != 0 && _weight != 0 && _height != 0.0 && _address != null;

  bool get getCustomerHasAlergies => _allergies.isNotEmpty;

  bool? get remindMeLater => _remindMeLater;

  void setRemindeMeLater() => {_remindMeLater = true, notifyListeners()};

  Future<void> setMood(
    MoodType mood, {
    double confidence = 0.0,
    MoodSource source = MoodSource.unknown,
  }) async {
    _currentMood = mood;
    _moodConfidence = confidence;
    _moodSource = source;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_mood', mood.name);
    await prefs.setString('mood_set_at', DateTime.now().toIso8601String());
    await prefs.setString('last_mood_source', source.name);
    await prefs.setDouble('last_mood_confidence', confidence);
  }

  Future<void> setUserMood(
    MoodType mood, {
    double confidence = 0.0,
    MoodSource source = MoodSource.unknown,
  }) {
    return setMood(
      mood,
      confidence: confidence,
      source: source,
    );
  }

  Future<void> clearMood() async {
    _currentMood = null;
    _moodConfidence = 0.0;
    _moodSource = MoodSource.unknown;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_mood');
    await prefs.remove('mood_set_at');
    await prefs.remove('last_mood_source');
    await prefs.remove('last_mood_confidence');

    notifyListeners();
  }

  void reset() {
    _address = null;
    _allergies = [];
    _dietaryPreferences = [];
    _firstName = null;
    _lastName = null;
    _phone = null;
    _profilePicture = null;
    _weight = null;
    _age = null;
    _height = null;
    _remindMeLater = null;
    _fcmToken = null;
    _targetWeight = null;
    _activityLevel = null;
    _gender = null;
    _customerId = null;
    _currentMood = null;
    _moodConfidence = 0.0;
    _moodSource = MoodSource.unknown;
    notifyListeners();
  }

  Future<void> loadPersistedMood() async {
    final prefs = await SharedPreferences.getInstance();
    final moodName = prefs.getString('last_mood');
    final setAtStr = prefs.getString('mood_set_at');
    final sourceName = prefs.getString('last_mood_source');

    if (moodName == null || setAtStr == null) {
      return;
    }

    final setAt = DateTime.tryParse(setAtStr);
    if (setAt == null) {
      return;
    }

    final isToday = DateUtils.isSameDay(setAt, DateTime.now());
    if (!isToday) {
      return;
    }

    final moodType = MoodTypeConfig.normalizeMood(moodName);
    final source = MoodSource.values.firstWhere(
      (item) => item.name == sourceName,
      orElse: () => MoodSource.unknown,
    );

    _currentMood = moodType;
    _moodSource = source;
    _moodConfidence = prefs.getDouble('last_mood_confidence') ?? 0.0;
    notifyListeners();
  }

  Future<void> loadUserPreferences() async {
    final customerId = _customerId;
    if (customerId == null || customerId.isEmpty) {
      return;
    }

    try {
      final customerData = await _dbService.getCustomer(customerId);
      if (customerData is! Map<String, dynamic>) {
        return;
      }

      _allergies = _normalizeStringList(
        customerData['alergies'] as List<dynamic>? ??
            customerData['allergies'] as List<dynamic>?,
      );
      _dietaryPreferences = _normalizeStringList(
        customerData['dietaryPreferences'] as List<dynamic>?,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  Future<void> saveAllergies(List<String> allergies) async {
    final normalizedAllergies = _normalizeStringList(allergies);
    final customerId = _customerId;

    if (customerId != null && customerId.isNotEmpty) {
      await _dbService.updateAlergies(
        allergies: normalizedAllergies,
        customerId: customerId,
      );
    }

    _allergies = normalizedAllergies;
    notifyListeners();
  }

  Future<void> saveDietaryPreferences(List<String> prefs) async {
    final normalizedPrefs = _normalizeStringList(prefs);
    final customerId = _customerId;

    if (customerId != null && customerId.isNotEmpty) {
      await _dbService.updateDietaryPreferences(
        customerId: customerId,
        dietaryPreferences: normalizedPrefs,
      );
    }

    _dietaryPreferences = normalizedPrefs;
    notifyListeners();
  }

  Future<void> setPhysicalInformation({
    required int age,
    required double height,
    required int weight,
    required String customerId,
  }) async {
    await _dbService.updatePhysicalInformation(
      age: age,
      height: height,
      weight: weight,
      customerId: customerId,
    );
    _age = age;
    _height = height;
    _weight = weight;

    final bmi = calculateBmi();
    if (bmi > 0) {
      await _bmiHistoryService.addReading(
        customerId: customerId,
        bmi: bmi,
        weight: weight,
        height: height,
      );
    }

    notifyListeners();
  }

  void setAddress({required String address}) {
    _address = address;
    notifyListeners();
  }

  Future<void> updateAddress({
    required String address,
    required String customerID,
  }) async {
    await _dbService.updateAddress(address: address, customerID: customerID);
    _address = address;
    notifyListeners();
  }

  Future<void> updateProfilePicturePathToDB(
    String imageUrl,
    String customerId,
  ) async {
    try {
      await _dbService.updateCustomerProfilePicture(
        customerId: customerId,
        imageUrl: imageUrl,
      );

      _profilePicture = imageUrl;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      rethrow;
    }
  }

  double calculateBmi() {
    final weight = _weight?.toDouble();
    final height = _height;

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      return 0;
    }

    final heightInMeter = height / 100;
    final bmi = weight / (heightInMeter * heightInMeter);

    if (!bmi.isFinite) {
      return 0;
    }

    return bmi;
  }

  Future<void> setTargetWeight({
    required double targetWeight,
    required String customerId,
  }) async {
    _customerId = customerId;
    await _dbService.updateTargetWeight(
      targetWeight: targetWeight,
      customerId: customerId,
    );
    _targetWeight = targetWeight;
    notifyListeners();
  }

  Future<void> setActivityLevel({
    required String activityLevel,
    required String customerId,
  }) async {
    _customerId = customerId;
    await _dbService.updateActivityLevel(
      activityLevel: activityLevel,
      customerId: customerId,
    );
    _activityLevel = activityLevel;
    notifyListeners();
  }

  Future<void> setGender({
    required String gender,
    required String customerId,
  }) async {
    _customerId = customerId;
    await _dbService.updateGender(gender: gender, customerId: customerId);
    _gender = gender;
    notifyListeners();
  }

  List<String> _normalizeStringList(List<dynamic>? values) {
    if (values == null) {
      return <String>[];
    }

    return values
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
