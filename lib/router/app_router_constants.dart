import 'dart:developer';

import 'package:flutter/material.dart';

class AppRouterConstants {
  static const String authenticationRouteName = 'auth';
  static const String homeRouteName = 'home';
  static const String homeIngredientRouteName = 'ingredients';
  static const String homeMealRecipieRouteName = 'recipie';
  static const String cartRouteName = 'cart';
  static const String profileRouteName = 'profile';
}

class AppRouterNaigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    log('did push Route $route');
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    log('did Remove Route');
    super.didRemove(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    log('did Pop Route');
    // TODO: implement didPop
    super.didPop(route, previousRoute);
  }
}
