import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> deleteCartItemDialog(
    BuildContext context, int index, String? mealName) {
  DefaultColors defaultColors = DefaultColors();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(mealName!),
        content: const Text(
          'Are you sure you wanted to delete this Item from Cart?',
        ),
        actions: <Widget>[
          ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(defaultColors.primaryColor)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )),
          ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(defaultColors.redColor)),
              onPressed: () {
                context.read<CartProvider>().deleteElement(index);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ))
        ],
      );
    },
  );
}
