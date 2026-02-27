import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FlutterToast {
  static void showToast(String message, Color color) {
    Fluttertoast.showToast(
        msg: message,
        fontSize: 16,
        textColor: Colors.white,        
        backgroundColor: color);
  }
}
