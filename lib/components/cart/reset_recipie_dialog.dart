import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';

Future<void> resetRecipieDialog(
    BuildContext context, String? mealName, Function() resetRecipie) {
  DefaultColors defaultColors = DefaultColors();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(mealName!),
        content: const Text(
          'Are you sure you wanted to reset the recipie ingredients? ',
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
                resetRecipie();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Reset',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ))
        ],
      );
    },
  );
}
