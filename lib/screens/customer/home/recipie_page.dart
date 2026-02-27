// import 'dart:math';

// import 'package:auto_height_grid_view/auto_height_grid_view.dart';
// import 'package:diet_app/components/cart/reset_recipie_dialog.dart';
// import 'package:diet_app/components/home/change_recipie_dialog.dart';
// import 'package:diet_app/components/loading.dart';
// import 'package:diet_app/firebase/db_service.dart';

// import 'package:diet_app/utilities/constants.dart';
// import 'package:diet_app/modals/cart_item.dart';

// import 'package:diet_app/providers/cart_provider.dart';
// import 'package:diet_app/providers/recipie_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class RecipieScreen extends StatefulWidget {
//   final String recipieId;
//   const RecipieScreen({super.key, required this.recipieId});

//   @override
//   State<RecipieScreen> createState() => _RecipieScreenState();
// }

// class _RecipieScreenState extends State<RecipieScreen> {
//   DefaultColors defaultColors = DefaultColors();
//   // final FirebaseService _firebaseService = FirebaseService();
//   final DBService dbService = DBService();
//   bool loading = true;

//   late Future<dynamic> ingredients;
//   void resetRecipie() {
//     setState(() {
//       ingredients = getRecipie();
//     });
//   }

//   List<Map<String, Map<String, dynamic>>> objectToArray({
//     required Map<String, dynamic> object,
//   }) {
//     List<Map<String, Map<String, dynamic>>> objectArray = [];

//     object.forEach((key, value) {
//       final Map<String, Map<String, dynamic>> singleObject = {
//         key: {
//           "isChangeAble": value['isChangeAble'],
//           "measurement": value['measurement'],
//         }
//       };
//       objectArray.add(singleObject);
//     });
//     return objectArray;
//     // Output the dynamic array
//   }

//   Future<dynamic> getRecipie() async {
//     final response = await dbService.getRecipie(widget.recipieId);
//     Map<String, dynamic> recipie = response['recipie'];
//     Future.microtask(() {
//       List<Map<String, Map<String, dynamic>>> recipieArray =
//           objectToArray(object: recipie);
//       context.read<RecipieProvider>().setRecipie(recipieArray);
//     });

//     return await response;
//   }

//   @override
//   void initState() {
//     super.initState();
//     ingredients = getRecipie();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container();
//     // return FutureBuilder(
//     //     future: ingredients,
//     //     builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
//     //       if (snapshot.connectionState == ConnectionState.waiting) {
//     //         return const LoadingSpinner();
//     //       } else if (snapshot.hasError) {
//     //         return Center(child: Text('Error: ${snapshot.error}'));
//     //       } else if (!snapshot.hasData || snapshot.data == null) {
//     //         return const Center(child: Text('No Data Found'));
//     //       } else if (snapshot.hasData) {
//     //         final RecipieProvider recipie = context.watch<RecipieProvider>();
//     //         return Column(
//     //           children: [
//     //             Expanded(
//     //               flex: 10,
//     //               child: SingleChildScrollView(
//     //                 child: Padding(
//     //                   padding: const EdgeInsets.symmetric(vertical: 30),
//     //                   child: Column(
//     //                     children: [
//     //                       Card(
//     //                         child: Container(
//     //                           height: 200,
//     //                           width: 200,
//     //                           decoration: BoxDecoration(
//     //                               borderRadius: BorderRadius.circular(12),
//     //                               image: DecorationImage(
//     //                                   image: NetworkImage(
//     //                                       snapshot.data['strMealThumb']))),
//     //                         ),
//     //                       ),
//     //                       const SizedBox(
//     //                         height: 10,
//     //                       ),
//     //                       Text(
//     //                         snapshot.data['strMeal'],
//     //                         style: TextStyle(
//     //                             color: defaultColors.maroonColor,
//     //                             fontWeight: FontWeight.bold,
//     //                             fontSize: 22),
//     //                       ),
//     //                       const SizedBox(
//     //                         height: 1,
//     //                       ),
//     //                       Text(
//     //                         "Ingredients",
//     //                         style: TextStyle(
//     //                             color: defaultColors.primaryColor,
//     //                             fontWeight: FontWeight.bold,
//     //                             fontSize: 20),
//     //                       ),
//     //                       const SizedBox(
//     //                         height: 10,
//     //                       ),
//     //                       AutoHeightGridView(
//     //                         crossAxisCount: 3,
//     //                         mainAxisSpacing: 10,
//     //                         crossAxisSpacing: 10,
//     //                         physics: const BouncingScrollPhysics(),
//     //                         padding: const EdgeInsets.all(12),
//     //                         shrinkWrap: true,
//     //                         itemCount: recipie.getLength,
//     //                         builder: (context, index) {
//     //                           String key = recipie.getRecipie[index].keys.first;
//     //                           String value = recipie.getRecipie[index][key]
//     //                               ?['measurement'];

//     //                           int rowIndex = index % 3;
//     //                           return Container(
//     //                             padding:
//     //                                 const EdgeInsets.symmetric(horizontal: 10),
//     //                             decoration: BoxDecoration(
//     //                               border: rowIndex != 0
//     //                                   ? Border(
//     //                                       left: BorderSide(
//     //                                           color: defaultColors.primaryColor
//     //                                               .withOpacity(0.3)),
//     //                                     )
//     //                                   : null,
//     //                             ),
//     //                             child: Column(
//     //                               mainAxisSize: MainAxisSize.min,
//     //                               children: [
//     //                                 Text(
//     //                                   key,
//     //                                   textAlign: TextAlign.center,
//     //                                   style: const TextStyle(
//     //                                       fontSize: 14,
//     //                                       fontWeight: FontWeight.bold),
//     //                                 ),
//     //                                 Text(
//     //                                   value,
//     //                                   textAlign: TextAlign.center,
//     //                                 ),
//     //                               ],
//     //                             ),
//     //                           );
//     //                         },
//     //                       ),
//     //                       const SizedBox(height: 20),
//     //                       const Text(
//     //                           "Want to change Quantity of Ingredients ?"),
//     //                       const SizedBox(height: 20),
//     //                       Row(
//     //                         mainAxisAlignment: MainAxisAlignment.center,
//     //                         children: [
//     //                           ElevatedButton(
//     //                               style: ButtonStyle(
//     //                                   elevation:
//     //                                       const WidgetStatePropertyAll(0.0),
//     //                                   backgroundColor: WidgetStatePropertyAll(
//     //                                       defaultColors.richBlackColor)),
//     //                               onPressed: () async {
//     //                                 await resetRecipieDialog(
//     //                                   context,
//     //                                   snapshot.data['strMeal'],
//     //                                   () {
//     //                                     resetRecipie();
//     //                                   },
//     //                                 );
//     //                               },
//     //                               child: const Text(
//     //                                 'Reset Recipie',
//     //                                 style: TextStyle(
//     //                                     color: Colors.white,
//     //                                     fontWeight: FontWeight.bold),
//     //                               )),
//     //                           const SizedBox(
//     //                             width: 10,
//     //                           ),
//     //                           ElevatedButton(
//     //                               style: ButtonStyle(
//     //                                   elevation:
//     //                                       const WidgetStatePropertyAll(0.0),
//     //                                   backgroundColor: WidgetStatePropertyAll(
//     //                                       defaultColors.primaryColor)),
//     //                               onPressed: () async {
//     //                                 await changeRecipieDialog(context,
//     //                                     widget.recipieId, recipie.getRecipie);
//     //                               },
//     //                               child: const Text(
//     //                                 'Click To Change',
//     //                                 style: TextStyle(
//     //                                     color: Colors.white,
//     //                                     fontWeight: FontWeight.bold),
//     //                               )),
//     //                         ],
//     //                       ),
//     //                       const SizedBox(
//     //                         height: 10,
//     //                       ),
//     //                       const Text("Or"),
//     //                       const SizedBox(
//     //                         height: 10,
//     //                       ),
//     //                       const Text(
//     //                         "Ask our Ai model to change it for you according to your Health! ",
//     //                         textAlign: TextAlign.center,
//     //                       ),
//     //                       const SizedBox(
//     //                         height: 10,
//     //                       ),
//     //                       ElevatedButton(
//     //                           style: ButtonStyle(
//     //                               elevation: const WidgetStatePropertyAll(0.0),
//     //                               backgroundColor: WidgetStatePropertyAll(
//     //                                   defaultColors.richBlackColor)),
//     //                           onPressed: () {},
//     //                           child: const Text(
//     //                             'Click To Change',
//     //                             style: TextStyle(
//     //                                 color: Colors.white,
//     //                                 fontWeight: FontWeight.bold),
//     //                           )),
//     //                     ],
//     //                   ),
//     //                 ),
//     //               ),
//     //             ),
//     //             Padding(
//     //               padding: const EdgeInsets.all(8.0),
//     //               child: SizedBox(
//     //                 width: double.infinity,
//     //                 child: ElevatedButton(
//     //                     style: ButtonStyle(
//     //                         visualDensity: VisualDensity.compact,
//     //                         backgroundColor: WidgetStatePropertyAll(
//     //                             defaultColors.primaryColor)),
//     //                     onPressed: () async {
//     //                       context.read<CartProvider>().addItem(
//     //                           CartItem(
//     //                               idMeal: snapshot.data['idMeal'],
//     //                               quantity: 1,
//     //                               price: Random().nextInt(200),
//     //                               strArea: snapshot.data['strArea'],
//     //                               strCategory: snapshot.data['strCategory'],
//     //                               strMeal: snapshot.data['strMeal'],
//     //                               strMealThumb: snapshot.data['strMealThumb'],
//     //                               strTags: snapshot.data['strTags'],
//     //                               ingredients: recipie.getRecipie),
//     //                           context,
//     //                           snapshot.data['strMeal']);
//     //                     },
//     //                     child: const Padding(
//     //                       padding: EdgeInsets.all(8.0),
//     //                       child: Text(
//     //                         "Add to Cart",
//     //                         style: TextStyle(
//     //                             fontWeight: FontWeight.bold,
//     //                             color: Colors.white,
//     //                             fontSize: 18),
//     //                       ),
//     //                     )),
//     //               ),
//     //             )
//     //           ],
//     //         );
//     //       } else {
//     //         return const Center(
//     //           child: Text('Some thing unexpected happaned'),
//     //         );
//     //       }
//     //     });
//   }
// }





// // import 'dart:math';

// // import 'package:auto_height_grid_view/auto_height_grid_view.dart';
// // import 'package:diet_app/components/home/change_recipie_dialog.dart';
// // import 'package:diet_app/components/loading.dart';
// // import 'package:diet_app/utilities/api_service.dart';
// // import 'package:diet_app/utilities/constants.dart';
// // import 'package:diet_app/utilities/modals/cart_item.dart';
// // import 'package:diet_app/utilities/modals/recipie.dart';
// // import 'package:diet_app/utilities/providers/cart_provider.dart';
// // import 'package:diet_app/utilities/providers/recipie_provider.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/scheduler.dart';
// // import 'package:provider/provider.dart';

// // class RecipieScreen extends StatefulWidget {
// //   final String recipieId;
// //   const RecipieScreen({super.key, required this.recipieId});

// //   @override
// //   State<RecipieScreen> createState() => _RecipieScreenState();
// // }

// // class _RecipieScreenState extends State<RecipieScreen> {
// //   ApiService apiService = ApiService();
// //   DefaultColors defaultColors = DefaultColors();

// //   void settRecipies(Recipie recipie) {}

// //   @override
// //   Widget build(BuildContext context) {
// //     return FutureBuilder(
// //       future: apiService.getRecipie(widget.recipieId),
// //       builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const LoadingSpinner();
// //         } else if (snapshot.hasError) {
// //           return Text('Error: ${snapshot.error}');
// //         } else if (!snapshot.hasData || snapshot.data == null) {
// //           return const Text('No Data Found');
// //         } else {
// //           Recipie? mealRecipie = context.watch<RecipieProvider>().getRecipie;

// //           var ingredient = snapshot.data['meals'][0];
// //           Recipie recipie = Recipie(ingredients: [], measurements: []);
// //           ingredient.forEach((String key, value) => {
// //                 if (key.contains('strIngredient') &&
// //                     value != null &&
// //                     (value.isNotEmpty || value != ""))
// //                   {recipie.ingredients!.add(value)}
// //                 else if (key.contains('strMeasure') &&
// //                     value != null &&
// //                     (value.isNotEmpty || value != ""))
// //                   recipie.measurements!.add(value)
// //               });
// //           WidgetsBinding.instance.addPostFrameCallback((callback) {
// //             context.read<RecipieProvider>().setRecipie(recipie);
// //           });
// //           return Column(
// //             children: [
// //               Flexible(
// //                 flex: 8,
// //                 child: SingleChildScrollView(
// //                   child: Padding(
// //                     padding: const EdgeInsets.symmetric(
// //                         vertical: 30, horizontal: 20),
// //                     child: Column(
// //                       children: [
// //                         Column(
// //                             crossAxisAlignment: CrossAxisAlignment.center,
// //                             children: [
// //                               Card(
// //                                 child: Container(
// //                                   height: 200,
// //                                   width: 200,
// //                                   decoration: BoxDecoration(
// //                                       borderRadius: BorderRadius.circular(12),
// //                                       image: DecorationImage(
// //                                           image: NetworkImage(
// //                                               ingredient['strMealThumb']))),
// //                                 ),
// //                               ),
// //                               Text(
// //                                 ingredient['strMeal'],
// //                                 style: TextStyle(
// //                                     color: defaultColors.maroonColor,
// //                                     fontWeight: FontWeight.bold,
// //                                     fontSize: 22),
// //                               ),
// //                               const SizedBox(
// //                                 height: 3,
// //                               ),
// //                               Text(
// //                                 "Ingredients",
// //                                 style: TextStyle(
// //                                     color: defaultColors.primaryColor,
// //                                     fontWeight: FontWeight.bold,
// //                                     fontSize: 20),
// //                               )
// //                             ]),
// //                         AutoHeightGridView(
// //                           crossAxisCount: 3,
// //                           mainAxisSpacing: 10,
// //                           crossAxisSpacing: 10,
// //                           physics: const BouncingScrollPhysics(),
// //                           padding: const EdgeInsets.all(12),
// //                           shrinkWrap: true,
// //                           itemCount: mealRecipie.ingredients!.length,
// //                           builder: (context, index) {
// //                             int rowIndex = index % 3;
// //                             return Container(
// //                               padding:
// //                                   const EdgeInsets.symmetric(horizontal: 10),
// //                               decoration: BoxDecoration(
// //                                 border: rowIndex != 0
// //                                     ? Border(
// //                                         left: BorderSide(
// //                                             color: defaultColors.primaryColor
// //                                                 .withOpacity(0.3)),
// //                                       )
// //                                     : null,
// //                               ),
// //                               child: Column(
// //                                 mainAxisSize: MainAxisSize.min,
// //                                 children: [
// //                                   Text(mealRecipie.ingredients![index]),
// //                                   Text(mealRecipie.measurements![index]),
// //                                 ],
// //                               ),
// //                             );
// //                           },
// //                         ),
// //                         const SizedBox(height: 20),
// //                         const Text("Want to change Quantity of Ingredients ?"),
// //                         const SizedBox(height: 20),
// //                         Row(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //                             ElevatedButton(
// //                                 style: ButtonStyle(
// //                                     elevation:
// //                                         const WidgetStatePropertyAll(0.0),
// //                                     backgroundColor: WidgetStatePropertyAll(
// //                                         defaultColors.richBlackColor)),
// //                                 onPressed: () async {},
// //                                 child: const Text(
// //                                   'Reset Recipie',
// //                                   style: TextStyle(
// //                                       color: Colors.white,
// //                                       fontWeight: FontWeight.bold),
// //                                 )),
// //                             const SizedBox(
// //                               width: 20,
// //                             ),
// //                             ElevatedButton(
// //                                 style: ButtonStyle(
// //                                     elevation:
// //                                         const WidgetStatePropertyAll(0.0),
// //                                     backgroundColor: WidgetStatePropertyAll(
// //                                         defaultColors.primaryColor)),
// //                                 onPressed: () async {
// //                                   await changeRecipieDialog(
// //                                       context,
// //                                       widget.recipieId,
// //                                       mealRecipie,
// //                                       mealRecipie.measurements!.first);
// //                                 },
// //                                 child: const Text(
// //                                   'Click To Change',
// //                                   style: TextStyle(
// //                                       color: Colors.white,
// //                                       fontWeight: FontWeight.bold),
// //                                 )),
// //                           ],
// //                         ),
// //                         const SizedBox(
// //                           height: 10,
// //                         ),
// //                         const Text("Or"),
// //                         const SizedBox(
// //                           height: 10,
// //                         ),
// //                         const Text(
// //                             "Ask our Ai model to change it for you according to your Health! "),
// //                         const SizedBox(
// //                           height: 10,
// //                         ),
// //                         ElevatedButton(
// //                             style: ButtonStyle(
// //                                 elevation: const WidgetStatePropertyAll(0.0),
// //                                 backgroundColor: WidgetStatePropertyAll(
// //                                     defaultColors.richBlackColor)),
// //                             onPressed: () {},
// //                             child: const Text(
// //                               'Click To Change',
// //                               style: TextStyle(
// //                                   color: Colors.white,
// //                                   fontWeight: FontWeight.bold),
// //                             )),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //               Flexible(
// //                   child: Padding(
// //                 padding: const EdgeInsets.all(8.0),
// //                 child: SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                       style: ButtonStyle(
// //                           visualDensity: VisualDensity.compact,
// //                           backgroundColor: WidgetStatePropertyAll(
// //                               defaultColors.primaryColor)),
// //                       onPressed: () {
// //                         context.read<CartProvider>().addItem(CartItem(
// //                             idMeal: ingredient['idMeal'],
// //                             quantity: 1,
// //                             price: Random().nextInt(200),
// //                             strArea: ingredient['strArea'],
// //                             strCategory: ingredient['strCategory'],
// //                             strMeal: ingredient['strMeal'],
// //                             strMealThumb: ingredient['strMealThumb'],
// //                             strTags: ingredient['strTags'],
// //                             ingredients: mealRecipie.ingredients,
// //                             measurements: mealRecipie.measurements));

// //                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //                             action: SnackBarAction(
// //                                 label: 'Undo',
// //                                 onPressed: () {
// //                                   context.read<CartProvider>().pop();
// //                                 }),
// //                             content: Text(ingredient['strMeal'] +
// //                                 " " +
// //                                 "Has been Added to your cart")));
// //                       },
// //                       child: const Padding(
// //                         padding: EdgeInsets.all(8.0),
// //                         child: Text(
// //                           "Add to Cart",
// //                           style: TextStyle(
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.white,
// //                               fontSize: 18),
// //                         ),
// //                       )),
// //                 ),
// //               ))
// //             ],
// //           );
// //         }
// //       },
// //     );
// //   }
// // }
