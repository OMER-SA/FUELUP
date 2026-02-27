import 'package:flutter/material.dart';

Future<void> emailSentForResetPasswordDialog(
    BuildContext context, String email) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 10),
            Text(
              'Reset Email Sent',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        content: Text(
          'A password reset link has been sent to $email. Please check your inbox and follow the instructions to reset your password.',
          style: TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Close',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
          ),
        ],
      );
    },
  );
}
