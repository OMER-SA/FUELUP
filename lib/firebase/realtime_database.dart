import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class RealDataBaseService {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('orders'); // Create an instance of DBService

  Future<String> addOrder({
    required String customerId,
    required String kitchenId,
    required String mealId,
    required int quantity,
    required String orderDate,
    required String address,
    required String kitchenName,
    required String kitchenAddress,
    required String mealName,
    required String customerName,
    required String mealPicture,
    required int price,
    String status = 'Order Placed',
    required List<Map<String, dynamic>> recipe,
    required List<dynamic> originalRecipe,
  }) async {
    try {
      // Generate a unique orderId
      String orderId = _databaseReference.child(customerId).push().key ?? '';

      await _databaseReference.child(orderId).set({
        'orderId': orderId,
        'customerId': customerId,
        'kitchenId': kitchenId,
        'mealId': mealId,
        'quantity': quantity,
        'orderDate': orderDate,
        'status': status,
        'price': price,
        'kitchenName': kitchenName,
        'kitchenAddress': kitchenAddress,
        'mealName': mealName,
        'address': address,
        'recipe': recipe,
        'customerName': customerName,
        'mealPicture': mealPicture,
        'originalRecipe': originalRecipe,
      });

      return orderId;
    } catch (e) {
      print('Error while adding order: $e');
      return "Error while adding order:";
    }
  }

  Future<void> updateOrder(
      {required String customerId,
      required String orderId,
      required String status}) async {
    try {
      await _databaseReference
          .child(customerId)
          .child(orderId)
          .update({'status': status});
    } catch (e) {
      print('Error while updating order: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _databaseReference.child(orderId).update({'status': newStatus});
    } catch (e) {
      print('Error while updating order status: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrdersByUserId(String userId) async {
    try {
      DatabaseEvent event = await _databaseReference
          .orderByChild('customerId')
          .equalTo(userId)
          .once();

      List<Map<String, dynamic>> userOrders = [];

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> ordersData =
            event.snapshot.value as Map<dynamic, dynamic>;

        for (var entry in ordersData.entries) {
          Map<String, dynamic> orderData =
              Map<String, dynamic>.from(entry.value);

          userOrders.add(orderData);
        }

        userOrders.sort((a, b) {
          DateTime dateA = DateTime.parse(a['orderDate']);
          DateTime dateB = DateTime.parse(b['orderDate']);
          return dateB.compareTo(dateA); // Latest first
        });
      }

      return userOrders;
    } catch (e) {
      print('Error while fetching orders by user ID: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrdersByKitchenId(
      String kitchenId) async {
    try {
      DatabaseEvent event = await _databaseReference
          .orderByChild('kitchenId')
          .equalTo(kitchenId)
          .once();

      List<Map<String, dynamic>> kitchenOrders = [];

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> ordersData =
            event.snapshot.value as Map<dynamic, dynamic>;

        for (var entry in ordersData.entries) {
          Map<String, dynamic> orderData =
              Map<String, dynamic>.from(entry.value);
          kitchenOrders.add(orderData);
        }

        kitchenOrders.sort((a, b) {
          DateTime dateA = DateTime.parse(a['orderDate']);
          DateTime dateB = DateTime.parse(b['orderDate']);
          return dateB.compareTo(dateA); // Latest first
        });
      }
      return kitchenOrders;
    } catch (e) {
      print('Error while fetching orders by kitchen ID: $e');
      rethrow;
    }
  }

  // New method to set up a listener
  StreamSubscription<DatabaseEvent> listenToOrdersByKitchenId(
      String kitchenId, Function(List<Map<String, dynamic>>) onUpdate) {
    return _databaseReference
        .orderByChild('kitchenId')
        .equalTo(kitchenId)
        .onValue
        .listen((DatabaseEvent event) async {
      if (event.snapshot.value != null) {
        final ordersData = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> updatedOrders = [];

        for (var entry in ordersData.entries) {
          final order = Map<String, dynamic>.from(entry.value as Map);
          order['orderId'] = entry.key;

          updatedOrders.add(order);
        }

        updatedOrders.sort((a, b) {
          DateTime dateA = DateTime.parse(a['orderDate']);
          DateTime dateB = DateTime.parse(b['orderDate']);
          return dateB.compareTo(dateA); // Latest first
        });

        onUpdate(updatedOrders);
      } else {
        onUpdate([]);
      }
    });
  }
}
