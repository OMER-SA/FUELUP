import 'dart:async';

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
  //User Collection

  Future storeUserData(User user, SingUpDto userData, String fcmToken) async {
    final userColl = <String, dynamic>{
      'email': userData.email,
      'role': userData.role,
      'fcmToken': fcmToken
    };

    await _firebaseFirestoreInstance
        .collection('users')
        .doc(user.uid)
        .set(userColl);

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
      await _firebaseFirestoreInstance
          .collection('cheffs')
          .doc(user.uid)
          .set(cheffCollection);
    } else {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(user.uid)
          .set(customerCollection);
    }
  }

  Future getCategories() async {
    try {
      final QuerySnapshot response =
          await _firebaseFirestoreInstance.collection('mealCategory').get();
      return response.docs.map((e) => e.data()).toList();
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getMeals(
      {String? category}) async {
    try {
      Query query = _firebaseFirestoreInstance.collection('kitchenMeals');

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
      print('Error fetching meals: $e');
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
      print("FireBaseException: $e");
    } catch (e) {
      print("Error: $e");
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
    // print("${ingredients.length} : ${measurments.length}");
    // print(ingredients);
    // print(measurments);
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
      print("Error while creating Recipie");
    }
  }

  Future getUser(String uuid) async {
    try {
      final DocumentSnapshot userDoc =
          await _firebaseFirestoreInstance.collection('users').doc(uuid).get();
      return userDoc.data();
    } catch (e) {
      print("Error while fetching user data: $e");
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
      print("Error while fetching Customers: $e");
    }
  }

  Future updateCustomerData(CompleteProfileData customerData) async {
    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerData.getUuid)
          .update(<String, dynamic>{
        'age': customerData.getAge,
        'height': customerData.getHeight,
        'weight': customerData.getWeight,
        'address': customerData.getAddress,
        'alergies': customerData.getSelectedAllergies
      });
      return "Data Update Sucessfully";
    } catch (e) {
      print("Error while Updating Customer Data: $e");
    }
  }

  Future updateAlergies(
      {required String customerId, required List<String> allergies}) async {
    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'alergies': allergies});
    } catch (e) {
      print("Error while Updating Customer Data: $e");
    }
  }

  Future<Map<String, String>?> updateName({
    required String firstName,
    required String lastName,
    required String customerId,
  }) async {
    try {
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
    } catch (e) {
      print("Error while Updating Customer Data: $e");
      return null;
    }
  }

  updatePhone({required String phone, required String customerId}) async {
    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({'phone': phone});
    } catch (e) {
      print("Error while Updating Customer Data: $e");
    }
  }

  updatePhysicalInformation(
      {required int age,
      required double height,
      required int weight,
      required String customerId}) async {
    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerId)
          .update({
        'age': age,
        'height': height,
        'weight': weight,
      });
    } catch (e) {
      print("Error while Updating Customer Data: $e");
    }
  }

  Future updateAddress(
      {required String address, required String customerID}) async {
    try {
      await _firebaseFirestoreInstance
          .collection('customers')
          .doc(customerID)
          .update({'address': address});
    } catch (e) {
      print("Error While updating Customer Address $e");
    }
  }

  //================================Kitchen ================================
  //================================Kitchen ================================
  //================================Kitchen ================================
  //================================Kitchen ================================
  //================================Kitchen ================================
  //================================Kitchen ================================
  //================================Kitchen ================================
  //================================Kitchen ================================

  Future getCheff(String uuid) async {
    print("uuid: $uuid");
    try {
      final DocumentSnapshot userDoc =
          await _firebaseFirestoreInstance.collection('cheffs').doc(uuid).get();
      print("userDoc.data() ${userDoc.data()}");
      return userDoc.data();
    } catch (e) {
      print("Error while fetching Cheff data: $e");
    }
  }

  Future storeCategory({required String category}) async {
    final payLoad = <String, dynamic>{"category": category};
    try {
      await _firebaseFirestoreInstance
          .collection('mealCategory')
          .doc(category)
          .set(payLoad);
    } catch (e) {
      print("Error while storing Category: $e");
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
      String? mealPicture}) async {
    try {
      await storeCategory(category: category);
      final List<Map<String, dynamic>> ingredients = [];
      for (var element in recipie) {
        ingredients.add({
          'measurement': element['measurement']?.text,
          'ingredient': element['ingredient']?.text,
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
        'recipie': ingredients
      };

      DocumentReference docRef = await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .add(payLoad);
      String docId = docRef.id;
      await docRef.update({'idMeal': docId});

      return docId;
    } catch (e) {
      print("Error while storing Meal: $e");
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
      print("Error fetching meals: $e");
      return [];
    }
  }

  Future<void> emptyFmcToken(String uid) async {
    try {
      await _firebaseFirestoreInstance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': ''});
    } catch (e) {
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
        print('Category "$category" deleted as it had no associated meals.');
      } else {
        print('Category "$category" still has associated meals. Not deleted.');
      }
    } catch (e) {
      print('Error while deleting unused category: $e');
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
    } catch (e) {
      print("Error deleting meal: $e");
    }
  }

  Future updateKitchenMeal(Map<String, dynamic> updatedMeal) async {
    try {
      await _firebaseFirestoreInstance
          .collection('kitchenMeals')
          .doc(updatedMeal['idMeal'])
          .update(updatedMeal);
    } catch (e) {
      print("Error updating meal: $e");
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
    } catch (e) {
      print("Error updating chef name: $e");
    }
  }

  updateChefPhone({required String phone, required String cheffId}) async {
    try {
      await _firebaseFirestoreInstance
          .collection('cheffs')
          .doc(cheffId)
          .update({'phone': phone});
      return true;
    } catch (e) {
      print("Error updating chef phone: $e");
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
    } catch (e) {
      print("Error updating customer profile picture: $e");
      rethrow;
    }
  }

  Future<void> updateCheffProfilePicture({
    required String cheffId,
    required String imageUrl,
  }) async {
    try {
      await _firebaseFirestoreInstance
          .collection('cheffs')
          .doc(cheffId)
          .update({'profilePicture': imageUrl});
    } catch (e) {
      print("Error updating customer profile picture: $e");
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
    } catch (e) {
      print("Error updating meal picture: $e");
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
    } catch (e) {
      print("Error updating chef profile picture: $e");
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
    } catch (e) {
      print("Error while ordering meal: $e");
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
        print('Meal not found for ID: $mealId');
        return null;
      }
    } catch (e) {
      print('Error fetching meal data: $e');
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
    } catch (e) {
      print("Error Updating Cheff Address: $e");
    }
  }

  Future updateFCMToken(
      {required String fcmToken, required String userID}) async {
    try {
      await _firebaseFirestoreInstance
          .collection('users')
          .doc(userID)
          .update({'fcmToken': fcmToken});
      return true;
    } catch (e) {
      print("Error while udpating FCMTOKEN");
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
      print(e);
    }
  }
}
