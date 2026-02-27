import 'dart:io';

import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    DefaultColors defaultColors = DefaultColors();
    return Center(
        child: Platform.isAndroid
            ? CircularProgressIndicator(
                color: defaultColors.primaryColor,
              )
            : CupertinoActivityIndicator(
              radius: 20,
                color: defaultColors.primaryColor,
              ));
  }
}
