import 'package:diet_app/components/loading.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';

Future<void> deleteMealDialog(BuildContext context,
    {required Function onDelete}) {
  final DefaultColors defaultColors = DefaultColors();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      bool loading = false;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Are you sure you want to delete this meal?'),
            actions: loading
                ? <Widget>[const LoadingSpinner()]
                : <Widget>[
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: ButtonStyleButton.allOrNull(
                            defaultColors.primaryColor),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            ButtonStyleButton.allOrNull(defaultColors.redColor),
                      ),
                      onPressed: () async {
                        setState(() {
                          loading = true;
                        });
                        await onDelete();
                        setState(() {
                          loading = false;
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
          );
        },
      );
    },
  );
}
