import 'package:diet_app/components/cart/delete_item_dialog.dart';
import 'package:diet_app/widgets/meal_image.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  DefaultColors defaultColors = DefaultColors();

  @override
  Widget build(BuildContext context) {
    CartProvider cartItems = context.watch<CartProvider>();

    if (cartItems.itemCount == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/cart/undraw_empty_cart_co35.svg',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 20),
          Text(
            'Your Cart Is Empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: defaultColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: () {
              context.go('/home');
            },
            child: const Text(
              'Continue Shopping',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 80,
        color: defaultColors.secondaryColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sub Total:',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  '${cartItems.getSubTotal().toStringAsFixed(2)} Rs',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: defaultColors.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                context.push('/cart/checkout');
              },
              child: const Text(
                'Checkout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: cartItems.itemCount,
        itemBuilder: (context, index) {
          final item = cartItems.cartItems.value[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: defaultColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: defaultColors.primaryColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MealImage(
                      meal: {
                        'mealPicture': item.mealPicture,
                        'mealName': item.name,
                        'category': item.category,
                        'tags': const <String>[],
                      },
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Price: ${item.price} Rs",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          "Total: ${cartItems.getItemTotal(index).toStringAsFixed(2)} Rs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: defaultColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => cartItems.decrement(
                              index: index,
                              context: context,
                              mealName: item.name,
                            ),
                          ),
                          Text(
                            item.quantity.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => cartItems.increment(index),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: defaultColors.redColor,
                        ),
                        onPressed: () =>
                            deleteCartItemDialog(context, index, item.name),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
