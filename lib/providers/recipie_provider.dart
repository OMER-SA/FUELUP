import 'package:flutter/material.dart';

class RecipieProvider with ChangeNotifier {
  List<Map<String, Map<String, dynamic>>> _recipie = [];

  List<Map<String, Map<String, dynamic>>> get getRecipie => _recipie;
  int get getLength => _recipie.length;

  void setRecipie(List<Map<String, Map<String, dynamic>>> recipie) {
    _recipie = recipie;
    notifyListeners();
  }

  void changeRecipie(List<TextEditingController> controllers) {
    for (var i = 0; i < _recipie.length; i++) {
      String key = _recipie[i].keys.first;
      _recipie[i][key]?['measurement'] = controllers[i].text;
    }
    notifyListeners();
  }
}
