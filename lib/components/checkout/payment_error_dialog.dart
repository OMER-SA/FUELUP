import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';

Future<void> paymentMethodErrorDialog(context) async {
  DefaultColors defaultColors = DefaultColors();
  return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(
                Icons.credit_card,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 10),
              Text(
                'Card Payment Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Server Error Please Select the Cash on delivery instead',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(
                  color: defaultColors.redColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      });
}
