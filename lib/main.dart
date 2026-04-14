
// // import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diet_app/firebase/quota_guard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diet_app/firebase/firebase_options.dart';
import 'package:diet_app/providers/chef_provider.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/cart_provider.dart';
import 'package:diet_app/providers/recipie_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/router/app_router_config.dart';
import 'package:diet_app/utilities/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  QuotaGuard.instance.resetSession();

  // Initialize Firebase and FirebaseAppCheck
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _recoverInterruptedLogout();
  // DISABLED: FirebaseAppCheck
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: kDebugMode
  //       ? AndroidProvider.debug
  //       : AndroidProvider.playIntegrity,
  //   appleProvider: AppleProvider.deviceCheck,
  // );
  
  // Register providers for state management
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => RecipieProvider()),
        ChangeNotifierProvider(create: (_) => UserIdProvider()),
        ChangeNotifierProvider(create: (_) => CheffProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _recoverInterruptedLogout() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final logoutInProgress = prefs.getBool('logout_in_progress') ?? false;

    if (!logoutInProgress) {
      return;
    }

    // FirebaseAuth is the only source of truth.
    // If a logout was interrupted, re-run signOut before clearing local session state.
    developer.log('🧭 STARTUP_LOGOUT_MARKER_FOUND');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      developer.log('⚠️  STARTUP_LOGOUT_SIGNOUT_IGNORED: error=$e');
    }

    await prefs.remove('uid');
    await prefs.remove('userRole');
    await prefs.remove('email');
    await prefs.remove('fcmToken');
    await prefs.remove('logout_in_progress');

    developer.log('✅ STARTUP_LOGOUT_RECOVERY_DONE');
  } catch (e) {
    developer.log('⚠️  STARTUP_LOGOUT_RECOVERY_IGNORED: error=$e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final DefaultColors defaultColors = DefaultColors();
    final AppRouter appRouter = AppRouter();
    final UserIdProvider userProvider = context.watch<UserIdProvider>();

    return MaterialApp.router(
      title: 'Fuel-Up',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(context, defaultColors),
      routerConfig: appRouter.getRouterConfig(userProvider),
    );
  }

  // Extract ThemeData for readability and reuse
  ThemeData _buildAppTheme(BuildContext context, DefaultColors defaultColors) {
    return ThemeData(
      primaryColor: defaultColors.primaryColor,
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: defaultColors.richBlackColor,
        displayColor: defaultColors.maroonColor,
      ),
      appBarTheme: AppBarTheme(
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: defaultColors.primaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 2,
            color: defaultColors.primaryColor,
          ),
        ),
        border: const OutlineInputBorder(),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
  }
}

