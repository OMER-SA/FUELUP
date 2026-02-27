import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_app/components/cart/delete_item_dialog.dart';
import 'package:diet_app/modals/cart_item.dart';

class CartProvider with ChangeNotifier {
  ValueNotifier<List<CartItem>> cartItems = ValueNotifier([]);
  final int _deliveryCharges = 200;

  CartProvider() {
    _loadCartFromPrefs();
  }

  int get itemCount => cartItems.value.length;

  Future<void> addItem(CartItem item, BuildContext context) async {
    int existingIndex =
        cartItems.value.indexWhere((cart) => cart.recipieId == item.recipieId);

    if (existingIndex != -1) {
      // Item already exists in cart
      CartItem existingItem = cartItems.value[existingIndex];
      bool isUpdated = false;

      if (existingItem.name != item.name ||
          existingItem.price != item.price ||
          !_areRecipesEqual(existingItem.recipie, item.recipie)) {
        cartItems.value[existingIndex] = item;
        isUpdated = true;
      } else if (existingItem.quantity != item.quantity) {
        cartItems.value[existingIndex].quantity = item.quantity;
        isUpdated = true;
      }

      _showCartSnackbar(
          context,
          item.name,
          isUpdated
              ? "${item.name} has been updated in your cart"
              : "${item.name} is already in your cart");
    } else {
      // New item, add to cart
      cartItems.value.add(item);
      _showCartSnackbar(
          context, item.name, "${item.name} has been added to your cart");
    }
    await _saveCartToPrefs();
    notifyListeners();
  }

  void _showCartSnackbar(
      BuildContext context, String itemName, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            context.push('/cart');
          },
        ),
      ),
    );
  }

  bool _areRecipesEqual(
      List<Map<String, dynamic>> recipe1, List<Map<String, dynamic>> recipe2) {
    if (recipe1.length != recipe2.length) return false;
    for (int i = 0; i < recipe1.length; i++) {
      if (recipe1[i]['ingredient'] != recipe2[i]['ingredient'] ||
          recipe1[i]['measurement'] != recipe2[i]['measurement'] ||
          recipe1[i]['isChangeAble'] != recipe2[i]['isChangeAble']) {
        return false;
      }
    }
    return true;
  }

  void removeItem(CartItem item) {
    cartItems.value.removeWhere((i) => i.recipieId == item.recipieId);
    _saveCartToPrefs();
    notifyListeners();
  }

  void clearCart() {
    cartItems.value.clear();
    _saveCartToPrefs();
    notifyListeners();
  }

  void increment(int index) {
    cartItems.value[index].quantity++;
    _saveCartToPrefs();
    notifyListeners();
  }

  void decrement(
      {required int index,
      required BuildContext context,
      required String mealName}) {
    if (cartItems.value[index].quantity > 1) {
      cartItems.value[index].quantity--;
    } else {
      deleteCartItemDialog(context, index, mealName);
    }
    _saveCartToPrefs();
    notifyListeners();
  }

  void deleteElement(int index) {
    if (cartItems.value.isNotEmpty) {
      cartItems.value.removeAt(index);
      _saveCartToPrefs();
    }
    notifyListeners();
  }

  int getItemTotal(int index) {
    return cartItems.value[index].price * cartItems.value[index].quantity;
  }

  double getSubTotal() {
    return cartItems.value
            .fold(0, (sum, item) => sum + (item.price * item.quantity)) +
        _deliveryCharges.toDouble();
  }

  // Save cart items to shared preferences
  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson =
        jsonEncode(cartItems.value.map((item) => item.toJson()).toList());
    await prefs.setString('cartItems', cartItemsJson);
  }

  // Load cart items from shared preferences
  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getString('cartItems');
    if (cartItemsJson != null) {
      final List decodedList = jsonDecode(cartItemsJson);
      cartItems.value =
          decodedList.map((json) => CartItem.fromJson(json)).toList();
      notifyListeners();
    }
  }

  double get getDeliveryCharges => _deliveryCharges.toDouble();
}
