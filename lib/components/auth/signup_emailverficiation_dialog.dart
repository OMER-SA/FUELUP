import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> emailVerficiationDialog(
    BuildContext context, String email, User user) async {
  Timer? timer;

  return await showDialog(
    context: context,
    barrierDismissible:
        false, // Prevent closing the dialog without verification
    builder: (BuildContext context) {
      // Start a timer to check the email verification status every 5 seconds
      timer = Timer.periodic(Duration(seconds: 3), (timer) async {
        await user.reload(); // Reload the user's data
        User? updatedUser = FirebaseAuth.instance.currentUser;

        if (updatedUser != null && updatedUser.emailVerified) {
          timer.cancel();
          if (context.mounted) {
            Navigator.of(context).pop(); // Close the dialog once verified
          }
          showDialog(
            context: context.mounted ? context : context,
            builder: (context) => AlertDialog(
              title: Text("Email Verified"),
              content:
                  Text("Your email has been verified. You can now proceed."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        }
      });

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Email Verification"),
            content: Text(
                "A verification email has been sent to $email. Please verify your email to complete registration."),
            actions: <Widget>[
              TextButton(
                child: Text("Check Again"),
                onPressed: () async {
                  await user.reload();
                  User? updatedUser = FirebaseAuth.instance.currentUser;
                  if (updatedUser != null && updatedUser.emailVerified) {
                    timer?.cancel(); // Stop the timer
                    if (!context.mounted) return;
                    Navigator.of(context)
                        .pop(); // Close the dialog once verified
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Email Verified"),
                        content: Text(
                            "Your email has been verified. You can now proceed."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              timer?.cancel();
                              Navigator.of(context).pop();
                            },
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // If email not verified, show an alert
                    setState(() {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Email Not Verified"),
                          content: Text(
                              "Please verify your email before proceeding."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                timer?.cancel();
                                Navigator.of(context).pop();
                              },
                              child: Text("OK"),
                            ),
                          ],
                        ),
                      );
                    });
                  }
                },
              ),
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  timer
                      ?.cancel(); // Cancel the timer when the dialog is dismissed
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}
