
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  // Initialize Firebase and FirebaseAppCheck
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  
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
      textTheme: GoogleFonts.quicksandTextTheme(
        Theme.of(context).textTheme,
      ).apply(
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



// import 'package:diet_app/firebase/firebase_options.dart';
// import 'package:diet_app/providers/chef_provider.dart';
// import 'package:diet_app/providers/customer_provider.dart';
// import 'package:diet_app/utilities/constants.dart';
// import 'package:diet_app/providers/cart_provider.dart';
// import 'package:diet_app/providers/recipie_provider.dart';
// import 'package:diet_app/providers/user_provider.dart';
// import 'package:diet_app/router/app_router_config.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   await FirebaseAppCheck.instance.activate(
//       androidProvider: AndroidProvider.debug,
//       appleProvider: AppleProvider.debug);
//   runApp(MultiProvider(providers: [
//     ChangeNotifierProvider(create: (_) => CartProvider()),
//     ChangeNotifierProvider(create: (_) => RecipieProvider()),
//     ChangeNotifierProvider(create: (_) => UserIdProvider()),
//     ChangeNotifierProvider(create: (_) => CheffProvider()),
//     ChangeNotifierProvider(create: (_) => CustomerProvider()),
//   ], child: const MyApp()));
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     final DefaultColors defaultColors = DefaultColors();
//     final AppRouter appRouter = AppRouter();
//     final UserIdProvider userProvider = context.watch<UserIdProvider>();
//     return MaterialApp.router(
//       title: 'Diet App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         textTheme: GoogleFonts.quicksandTextTheme(Theme.of(context).textTheme)
//             .apply(
//                 bodyColor: defaultColors.richBlackColor,
//                 displayColor: defaultColors.maroonColor),
//         appBarTheme: AppBarTheme(
//             elevation: 1,
//             centerTitle: true,
//             titleTextStyle: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: defaultColors.primaryColor,
//             )),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ButtonStyle(
//               shape: WidgetStatePropertyAll(RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(4)))),
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           focusedBorder: OutlineInputBorder(
//               borderSide:
//                   BorderSide(width: 2, color: defaultColors.primaryColor)),
//           border: const OutlineInputBorder(),
//           floatingLabelBehavior: FloatingLabelBehavior.always,
//         ),
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       routerConfig: appRouter.getRouterConfig(userProvider),
//       // routerDelegate: appRouter.goRouter.routerDelegate,
//       // routeInformationParser: appRouter.goRouter.routeInformationParser,
//       // routeInformationProvider: appRouter.goRouter.routeInformationProvider,
//     );
//   }
// }
