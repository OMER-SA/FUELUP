import 'dart:async';
import 'dart:developer' as developer;

import 'package:diet_app/firebase/quota_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diet_app/modals/complete_profile_modal.dart';
import 'package:diet_app/modals/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diet_app/firebase/firebase_storage.dart';

import 'package:image_picker/image_picker.dart';

class DBService {
  final FirebaseFirestore _firebaseFirestoreInstance =
      FirebaseFirestore.instance;
  final FirebaseDataStorage _firebaseStorage = FirebaseDataStorage();

  bool _shouldSkipWrite(String operation) {
    if (!QuotaGuard.instance.quotaExceeded) {
      return false;
    }

    developer.log('WRITE_SKIPPED_QUOTA_ACTIVE: operation=$operation');
    return true;
  }

  bool _markQuotaIfNeeded(Object error, String operation) {
    return QuotaGuard.instance.markIfQuotaExceeded(
      error,
      operation: operation,
    );
  }

  Future<T?> _guardedWrite<T>(
    String operation,
    Future<T> Function() action, {
    T? fallback,
  }) async {
    if (_shouldSkipWrite(operation)) {
      return fallback;
    }

    try {
      return await action();
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, operation)) {
        return fallback;
      }
      rethrow;
    } catch (e) {
      if (_markQuotaIfNeeded(e, operation)) {
        return fallback;
      }
      rethrow;
    }
  }

  //User Collection

  Future storeUserData(User user, SingUpDto userData, String fcmToken) async {
    if (_shouldSkipWrite('storeUserData')) {
      return;
    }

    final userColl = <String, dynamic>{
      'email': userData.email,
      'role': userData.role,
      'fcmToken': fcmToken,
      // Backup profile fields to recover from partial writes/doc loss.
      'firstName': userData.firstName,
      'lastName': userData.lastName,
      'phone': userData.phone,
      'kitchenName': userData.kitchenName,
    };

    try {
      await _firebaseFirestoreInstance
          .collection('users')
          .doc(user.uid)
          .set(userColl);
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'storeUserData.users.set')) {
        return;
      }
      rethrow;
    }

    final cheffCollection = <String, dynamic>{
      'uid': user.uid,
      'kitchenName': userData.kitchenName,
      'phone': userData.phone,
      'bannerPicture': null,
      'profilePicture': null,
      'address': null
    };

    final customerCollection = <String, dynamic>{
      'uid': user.uid,
      'firstName': userData.firstName,
      'lastName': userData.lastName,
      'phone': userData.phone,
      'address': null,
      'weight': null,
      'height': null,
      'alergies': <String>[],
      'age': null,
      'profilePicture': null,
    };

    if (userData.role == "cheff") {
      try {
        await _firebaseFirestoreInstance
            .collection('cheffs')
            .doc(user.uid)
            .set(cheffCollection);
      } on FirebaseException catch (e) {
        if (_markQuotaIfNeeded(e, 'storeUserData.cheffs.set')) {
          return;
        }
        rethrow;
      }
    } else {
      try {
        await _firebaseFirestoreInstance
            .collection('customers')
            .doc(user.uid)
            .set(customerCollection);
      } on FirebaseException catch (e) {
        if (_markQuotaIfNeeded(e, 'storeUserData.customers.set')) {
          return;
        }
        rethrow;
      }
    }
  }

  Future getCategories() async {
    try {
      final QuerySnapshot response =
          await _firebaseFirestoreInstance.collection('mealCategory').get();
      return response.docs.map((e) => e.data()).toList();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getMeals(
      {String? category}) async {
    try {
      Query query = _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .where('available', isEqualTo: true);

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      final QuerySnapshot response = await query.get();

      Map<String, List<Map<String, dynamic>>> groupedMeals = {};

      for (var doc in response.docs) {
        var mealData = doc.data() as Map<String, dynamic>;
        String chefId = mealData['cheffId'] as String;

        if (!groupedMeals.containsKey(chefId)) {
          groupedMeals[chefId] = [];
        }

        groupedMeals[chefId]!.add({
          ...mealData,
          'id': doc.id, // Include the document ID
        });
      }

      return groupedMeals;
    } catch (e) {
      debugPrint('Error fetching meals: $e');
      return {}; // Return an empty map in case of error
    }
  }

  Future getRecipie(String idMeal) async {
    try {
      final QuerySnapshot response = await _firebaseFirestoreInstance
          .collection('recipie')
          .where('idMeal', isEqualTo: idMeal)
          .get();
      return response.docs.first.data();
    } on FirebaseException catch (e) {
      debugPrint("FireBaseException: $e");
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future storeRecipie(
      {required String id,
      required String name,
      required String categoryName,
      required String area,
      required String instructions,
      required String tags,
      required String youtubeVideo,
      required int price,
      required List<String> ingredients,
      required List<String> measurments,
      required String imgUrl}) async {
    final Map<String, Map<String, dynamic>> recipie = {};
    if (ingredients.length == measurments.length) {
      for (var i = 0; i < ingredients.length; i++) {
        recipie[ingredients[i]] = {
          "measurement": measurments[i],
          "isChangeAble": i == 0 ? false : true
        };
      }
    }
    // debugPrint("${ingredients.length} : ${measurments.length}");
    // debugPrint(ingredients);
    // debugPrint(measurments);
    final categoryMap = <String, dynamic>{
      "idMeal": id,
      "strMeal": name,
      "strCategory": categoryName,
      "strArea": area,
      "strInstructions": instructions,
      "strMealThumb": imgUrl,
      "strTags": tags,
      "price": price,
      "strYoutube": youtubeVideo,
      "recipie": recipie,
    };
    try {
      await FirebaseFirestore.instance
          .collection('recipie')
          .doc(id)
          .set(categoryMap);
    } catch (e) {
      debugPrint("Error while creating Recipie");
    }
  }

  Future getUser(String uuid) async {
    try {
      developer.log('📖 DB_READ_USER: uid=$uuid');
      final DocumentSnapshot userDoc =
          await _firebaseFirestoreInstance.collection('users').doc(uuid).get();
      
      if (userDoc.exists) {
        developer.log('✅ DB_READ_USER_SUCCESS: uid=$uuid');
      } else {
        developer.log('⚠️  DB_READ_USER_NOT_FOUND: uid=$uuid');
      }
      return userDoc.data();
    } catch (e) {
      developer.log('❌ DB_READ_USER_ERROR: uid=$uuid, error=$e');
      debugPrint("Error while fetching user data: $e");
    }
  }

  Future<Map<String, dynamic>?> recoverUserProfileDoc({
    required String uid,
    required String email,
  }) async {
    try {
      final userDocRef = _firebaseFirestoreInstance.collection('users').doc(uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists && userDoc.data() != null) {
        final existing = Map<String, dynamic>.from(userDoc.data()! as Map);
        final hasRole =
            existing['role'] is String && (existing['role'] as String).isNotEmpty;
        final hasEmail = existing['email'] is String &&
            (existing['email'] as String).isNotEmpty;
        if (hasRole && hasEmail) {
          return existing;
        }
      }

      final cheffDoc =
          await _firebaseFirestoreInstance.collection('cheffs').doc(uid).get();
      if (cheffDoc.exists) {
        final payload = <String, dynamic>{
          'email': email,
          'role': 'cheff',
          'fcmToken': '',
        };
        await userDocRef.set(payload, SetOptions(merge: true));
        return payload;
      }

      final customerDoc =
          await _firebaseFirestoreInstance.collection('customers').doc(uid).get();
      if (customerDoc.exists) {
        final payload = <String, dynamic>{
          'email': email,
          'role': 'customer',
          'fcmToken': '',
        };
        await userDocRef.set(payload, SetOptions(merge: true));
        return payload;
      }

      if (userDoc.exists && userDoc.data() != null) {
        final existing = Map<String, dynamic>.from(userDoc.data()! as Map);
        if (existing['email'] == null || (existing['email'] as String).isEmpty) {
          existing['email'] = email;
        }
        if ((existing['role'] as String?)?.isEmpty ?? true) {
          existing['role'] = 'customer';
        }
        if (existing['fcmToken'] == null) {
          existing['fcmToken'] = '';
        }
        await userDocRef.set(existing, SetOptions(merge: true));
        return existing;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getCanonicalRole(String uid) async {
    try {
      final cheffDoc =
          await _firebaseFirestoreInstance.collection('cheffs').doc(uid).get();
      if (cheffDoc.exists) return 'cheff';

      final customerDoc = await _firebaseFirestoreInstance
          .collection('customers')
          .doc(uid)
          .get();
      if (customerDoc.exists) return 'customer';

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserRole({
    required String uid,
    required String role,
    required String email,
  }) async {
    if (_shouldSkipWrite('updateUserRole')) {
      return;
    }

    developer.log('📝 DB_WRITE_UPDATE_ROLE: uid=$uid, role=$role, email=$email');
    try {
      await _firebaseFirestoreInstance.collection('users').doc(uid).set({
        'role': role,
        'email': email,
      }, SetOptions(merge: true));
      developer.log('✅ DB_WRITE_UPDATE_ROLE_SUCCESS: uid=$uid');
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateUserRole')) {
        return;
      }
      developer.log('❌ DB_WRITE_UPDATE_ROLE_ERROR: uid=$uid, error=$e');
      rethrow;
    }
  }

  Future<void> ensureRoleProfileDoc({
    required String uid,
    required String role,
    required String email,
  }) async {
    final userDoc = await _firebaseFirestoreInstance.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    if (role == 'customer') {
      final customerRef = _firebaseFirestoreInstance.collection('customers').doc(uid);
      final customerDoc = await customerRef.get();
      if (!customerDoc.exists) {
        final localPart = email.contains('@') ? email.split('@').first : '';
        final backupFirstName = (userData['firstName'] ?? '').toString().trim();
        final backupLastName = (userData['lastName'] ?? '').toString().trim();
        final backupPhone = (userData['phone'] ?? '').toString().trim();
        final payload = <String, dynamic>{
          'uid': uid,
          'firstName': backupFirstName.isNotEmpty ? backupFirstName : localPart,
          'lastName': backupLastName,
          'phone': backupPhone,
          'address': null,
          'weight': null,
          'height': null,
          'alergies': <String>[],
          'age': null,
          'profilePicture': null,
        };
        await customerRef.set(payload, SetOptions(merge: true));
      }
      if (customerDoc.exists && customerDoc.data() != null) {
        final existing = Map<String, dynamic>.from(customerDoc.data()!);
        final backupFirstName = (userData['firstName'] ?? '').toString().trim();
        final backupLastName = (userData['lastName'] ?? '').toString().trim();
        final backupPhone = (userData['phone'] ?? '').toString().trim();
        final updates = <String, dynamic>{};

        final currentFirstName = (existing['firstName'] ?? '').toString().trim();
        final currentLastName = (existing['lastName'] ?? '').toString().trim();
        final currentPhone = (existing['phone'] ?? '').toString().trim();

        if (currentFirstName.isEmpty && backupFirstName.isNotEmpty) {
          updates['firstName'] = backupFirstName;
        }
        if (currentLastName.isEmpty && backupLastName.isNotEmpty) {
          updates['lastName'] = backupLastName;
        }
        if (currentPhone.isEmpty && backupPhone.isNotEmpty) {
          updates['phone'] = backupPhone;
        }

        if (updates.isNotEmpty) {
          await customerRef.set(updates, SetOptions(merge: true));
        }
      }
      return;
    }

    if (role == 'cheff') {
      final cheffRef = _firebaseFirestoreInstance.collection('cheffs').doc(uid);
      final cheffDoc = await cheffRef.get();
      if (!cheffDoc.exists) {
        final backupKitchenName = (userData['kitchenName'] ?? '').toString().trim();
        final backupPhone = (userData['phone'] ?? '').toString().trim();
        await cheffRef.set({
          'uid': uid,
          'kitchenName': backupKitchenName,
          'phone': backupPhone,
          'bannerPicture': null,
          'profilePicture': null,
          'address': null,
        }, SetOptions(merge: true));
      }
    }
  }

  Future getCustomer(String customerId) async {
    try {
      final DocumentSnapshot customerData = await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .get();
      return customerData.data();
    } catch (e) {
      debugPrint("Error while fetching Customers: $e");
    }
  }

  Future updateCustomerData(CompleteProfileData customerData) async {
    return _guardedWrite<String>(
      'updateCustomerData',
      () async {
        await _firebaseFirestoreInstance
            .collection('customers')
            .doc(customerData.getUuid)
            .update(<String, dynamic>{
          'age': customerData.getAge,
          'height': customerData.getHeight,
          'weight': customerData.getWeight,
          'address': customerData.getAddress,
          'alergies': customerData.getSelectedAllergies,
        });
        return "Data Update Sucessfully";
      },
      fallback: null,
    );
  }

  Future updateAlergies(
      {required String customerId, required List<String> allergies}) async {
    return _guardedWrite<void>('updateAlergies', () async {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'alergies': allergies});
    });
  }

  Future updateDietaryPreferences({
    required String customerId,
    required List<String> dietaryPreferences,
  }) async {
    return _guardedWrite<void>('updateDietaryPreferences', () async {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'dietaryPreferences': dietaryPreferences});
    });
  }

  Future<Map<String, String>?> updateName({
    required String firstName,
    required String lastName,
    required String customerId,
  }) async {
    return _guardedWrite<Map<String, String>?>(
      'updateName',
      () async {
      DocumentReference docRef =
          _firebaseFirestoreInstance.collection('customers').doc(customerId);

      await docRef.update({'firstName': firstName, 'lastName': lastName});

      // Fetch the updated document
      DocumentSnapshot updatedDoc = await docRef.get();
      Map<String, dynamic> data = updatedDoc.data() as Map<String, dynamic>;

      return {
        'firstName': data['firstName'] as String,
        'lastName': data['lastName'] as String
      };
      },
      fallback: null,
    );
  }

  updatePhone({required String phone, required String customerId}) async {
    return _guardedWrite<void>('updatePhone', () async {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'phone': phone});
    });
  }

  updatePhysicalInformation(
      {required int age,
      required double height,
      required int weight,
      required String customerId}) async {
    return _guardedWrite<void>('updatePhysicalInformation', () async {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({
        'age': age,
        'height': height,
        'weight': weight,
      });
    });
  }

  Future updateAddress(
      {required String address, required String customerID}) async {
    return _guardedWrite<void>('updateAddress', () async {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerID)
          .update({'address': address});
    });
  }

  //================================ Kitchen ================================

  Future getCheff(String uuid) async {
    debugPrint("uuid: $uuid");
    try {
      final DocumentSnapshot userDoc =
          await _firebaseFirestoreInstance.collection('cheffs').doc(uuid).get();
      debugPrint("userDoc.data() ${userDoc.data()}");
      return userDoc.data();
    } catch (e) {
      debugPrint("Error while fetching Cheff data: $e");
    }
  }

  Future storeCategory({required String category}) async {
    final payLoad = <String, dynamic>{"category": category};
    try {
      await _firebaseFirestoreInstance
          .collection('mealCategory')
          .doc(category)
          .set(payLoad);
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'storeCategory')) {
        return;
      }
      debugPrint("Error while storing Category: $e");
    }
  }

  Future storeMeal(
      {required String category,
      required String cheffId,
      required String mealName,
      required String price,
      required String discription,
      required String kitchenName,
      required List<Map<String, dynamic>> recipie,
      List<String> tags = const [],
      List<String> allergens = const [],
      List<String> dietaryLabels = const [],
      double protein = 0.0,
      String prepStyle = '',
      String? mealPicture}) async {
    try {
      await storeCategory(category: category);
      final List<Map<String, dynamic>> ingredients = [];
      int totalCalories = 0;
      for (var element in recipie) {
        final cal = int.tryParse(element['calories']?.text ?? '') ?? 0;
        totalCalories += cal;
        ingredients.add({
          'measurement': element['measurement']?.text,
          'ingredient': element['ingredient']?.text,
          'calories': cal,
          'isChangeAble': element['isChangeAble']
        });
      }
      final payLoad = {
        'kitchenName': kitchenName,
        'cheffId': cheffId,
        'category': category,
        'mealName': mealName,
        'price': int.parse(price),
        'description': discription,
        'mealPicture': mealPicture,
        'recipie': ingredients,
        'calories': totalCalories,
        'available': true,
        'tags': tags,
        'allergens': allergens,
        'dietaryLabels': dietaryLabels,
        'protein': protein,
        'prepStyle': prepStyle,
        'autoTagged': false,
        'autoTagModel': '',
      };

      DocumentReference docRef = await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .add(payLoad);
      String docId = docRef.id;
      await docRef.update({'idMeal': docId});

      return docId;
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'storeMeal')) {
        return null;
      }
      debugPrint("Error while storing Meal: $e");
      return null;
    } catch (e) {
      debugPrint("Error while storing Meal: $e");
      return null;
    }
  }

  Future getKitchenMeals(String cheffId) async {
    try {
      final QuerySnapshot mealData = await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .where('cheffId', isEqualTo: cheffId)
          .get();

      List<Map<String, dynamic>> meals = mealData.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return meals;
    } catch (e) {
      debugPrint("Error fetching meals: $e");
      return [];
    }
  }

  Future<void> emptyFmcToken(String uid) async {
    if (_shouldSkipWrite('emptyFmcToken')) {
      return;
    }

    try {
      await _firebaseFirestoreInstance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': ''}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'emptyFmcToken')) {
        return;
      }
      rethrow;
    }
  }

  Future<void> deleteUnusedCategory(String category) async {
    try {
      // Check if there are any meals with this category
      QuerySnapshot mealsSnapshot = await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .where('category', isEqualTo: category)
          .limit(1)
          .get();

      // If no meals found with this category, delete the category
      if (mealsSnapshot.docs.isEmpty) {
        await _firebaseFirestoreInstance
            .collection('mealCategory')
            .doc(category)
            .delete();
        debugPrint('Category "$category" deleted as it had no associated meals.');
      } else {
        debugPrint('Category "$category" still has associated meals. Not deleted.');
      }
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'deleteUnusedCategory')) {
        return;
      }
      debugPrint('Error while deleting unused category: $e');
    } catch (e) {
      debugPrint('Error while deleting unused category: $e');
    }
  }

  // Modify the deleteKitchenMeal method to check for unused categories
  Future deleteKitchenMeal({required String mealId}) async {
    try {
      // Get the meal document before deleting it
      DocumentSnapshot mealDoc = await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .doc(mealId)
          .get();

      // Delete the meal
      await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .doc(mealId)
          .delete();

      // Check if the category is now unused
      if (mealDoc.exists) {
        String category = mealDoc.get('category');
        await deleteUnusedCategory(category);
      }
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'deleteKitchenMeal')) {
        return;
      }
      debugPrint("Error deleting meal: $e");
    } catch (e) {
      debugPrint("Error deleting meal: $e");
    }
  }

  Future updateKitchenMeal(Map<String, dynamic> updatedMeal) async {
    try {
      await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .doc(updatedMeal['idMeal'])
          .update(updatedMeal);
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateKitchenMeal')) {
        return;
      }
      debugPrint("Error updating meal: $e");
    } catch (e) {
      debugPrint("Error updating meal: $e");
    }
  }

  updateChefName({required String kitchenName, required String cheffId}) async {
    WriteBatch batch = _firebaseFirestoreInstance.batch();
    try {
      await _firebaseFirestoreInstance
          .collection('cheffs')
          .doc(cheffId)
          .update({'kitchenName': kitchenName});

      QuerySnapshot querySnapshot = await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .where('cheffId', isEqualTo: cheffId)
          .get();

      for (var docs in querySnapshot.docs) {
        batch.update(docs.reference, {'kitchenName': kitchenName});
      }

      await batch.commit();
      return true;
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateChefName')) {
        return false;
      }
      debugPrint("Error updating chef name: $e");
      return false;
    } catch (e) {
      debugPrint("Error updating chef name: $e");
      return false;
    }
  }

  updateChefPhone({required String phone, required String cheffId}) async {
    try {
      await _firebaseFirestoreInstance
          .collection('cheffs')
          .doc(cheffId)
          .update({'phone': phone});
      return true;
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateChefPhone')) {
        return false;
      }
      debugPrint("Error updating chef phone: $e");
      return false;
    } catch (e) {
      debugPrint("Error updating chef phone: $e");
      return false;
    }
  }

  //Customer Section

  Future<void> updateCustomerProfilePicture({
    required String customerId,
    required String imageUrl,
  }) async {
    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'profilePicture': imageUrl});
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateCustomerProfilePicture')) {
        return;
      }
      debugPrint("Error updating customer profile picture: $e");
      rethrow;
    } catch (e) {
      debugPrint("Error updating customer profile picture: $e");
      rethrow;
    }
  }



  Future<void> updateMealPicture({
    required String mealId,
    required String imageUrl,
  }) async {
    try {
      await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .doc(mealId)
          .update({'mealPicture': imageUrl});
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateMealPicture')) {
        return;
      }
      debugPrint("Error updating meal picture: $e");
      rethrow;
    } catch (e) {
      debugPrint("Error updating meal picture: $e");
      rethrow;
    }
  }

  Future<void> updateChefProfilePicture({
    required String cheffId,
    required String imageUrl,
  }) async {
    try {
      await _firebaseFirestoreInstance
          .collection('cheffs')
          .doc(cheffId)
          .update({'profilePicture': imageUrl});
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateChefProfilePicture')) {
        return;
      }
      debugPrint("Error updating chef profile picture: $e");
      rethrow;
    } catch (e) {
      debugPrint("Error updating chef profile picture: $e");
      rethrow;
    }
  }

  Future<String> uploadMealPicture(XFile imageFile, String chefId) async {
    return await _firebaseStorage.uploadMealPicture(imageFile, chefId);
  }

  Future<void> order(
      String customerId, String mealId, int quantity, String orderDate) async {
    try {
      await _firebaseFirestoreInstance.collection('orders').add({
        'customerId': customerId,
        'mealId': mealId,
        'quantity': quantity,
        'orderDate': orderDate,
        'status': 'pending',
      });
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'order')) {
        return;
      }
      debugPrint("Error while ordering meal: $e");
      rethrow;
    } catch (e) {
      debugPrint("Error while ordering meal: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getMealById(String mealId) async {
    try {
      DocumentSnapshot mealDoc = await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .doc(mealId)
          .get();

      if (mealDoc.exists) {
        return mealDoc.data() as Map<String, dynamic>;
      } else {
        debugPrint('Meal not found for ID: $mealId');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching meal data: $e');
      return null;
    }
  }

  Future updateChefAddress(
      {required String address, required String chefId}) async {
    try {
      await _firebaseFirestoreInstance
          .collection('cheffs')
          .doc(chefId)
          .update({'address': address});
      return true;
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateChefAddress')) {
        return false;
      }
      debugPrint("Error Updating Cheff Address: $e");
      return false;
    } catch (e) {
      debugPrint("Error Updating Cheff Address: $e");
      return false;
    }
  }

  Future updateFCMToken(
      {required String fcmToken, required String userID}) async {
    if (_shouldSkipWrite('updateFCMToken')) {
      return false;
    }

    try {
      await _firebaseFirestoreInstance
          .collection('users')
          .doc(userID)
          .set({'fcmToken': fcmToken}, SetOptions(merge: true));
      return true;
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateFCMToken')) {
        return false;
      }
      debugPrint("Error while udpating FCMTOKEN");
      return false;
    } catch (e) {
      debugPrint("Error while udpating FCMTOKEN: $e");
      return false;
    }
  }

  Future getUserFCMToken(String userID) async {
    try {
      final DocumentSnapshot userDoc = await _firebaseFirestoreInstance
          .collection('users')
          .doc(userID)
          .get();
      return userDoc.data();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateTargetWeight(
      {required double targetWeight, required String customerId}) async {
    if (_shouldSkipWrite('updateTargetWeight')) {
      return;
    }

    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'targetWeight': targetWeight});
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateTargetWeight')) {
        return;
      }
      debugPrint('Error updating target weight: $e');
    } catch (e) {
      debugPrint('Error updating target weight: $e');
    }
  }

  Future<void> updateActivityLevel(
      {required String activityLevel, required String customerId}) async {
    if (_shouldSkipWrite('updateActivityLevel')) {
      return;
    }

    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'activityLevel': activityLevel});
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateActivityLevel')) {
        return;
      }
      debugPrint('Error updating activity level: $e');
    } catch (e) {
      debugPrint('Error updating activity level: $e');
    }
  }

  Future<void> updateGender(
      {required String gender, required String customerId}) async {
    if (_shouldSkipWrite('updateGender')) {
      return;
    }

    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'gender': gender});
    } on FirebaseException catch (e) {
      if (_markQuotaIfNeeded(e, 'updateGender')) {
        return;
      }
      debugPrint('Error updating gender: $e');
    } catch (e) {
      debugPrint('Error updating gender: $e');
    }
  }
}
