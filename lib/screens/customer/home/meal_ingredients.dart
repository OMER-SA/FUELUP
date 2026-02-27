import 'package:diet_app/firebase/db_service.dart';


import 'package:flutter/material.dart';

class MealIngredientsScreen extends StatefulWidget {
  final String categoryName;
  const MealIngredientsScreen({super.key, required this.categoryName});

  @override
  State<MealIngredientsScreen> createState() => _MealIngredientsScreenState();
}

class _MealIngredientsScreenState extends State<MealIngredientsScreen> {
  final DBService dbService = DBService();

  @override
  Widget build(BuildContext context) {    
    return Container();
    // return SafeArea(
    //     child: FutureBuilder(
    //         future: dbService.getMeals(),
    //         builder: (context, snapshot) {
    //           if (snapshot.connectionState == ConnectionState.waiting) {
    //             return const LoadingSpinner();
    //           } else if (snapshot.hasError) {
    //             return Text('Error: ${snapshot.error}');
    //           } else if (!snapshot.hasData || snapshot.data == null) {
    //             return const Text('No Data Found');
    //           } else {
    //             return ListView.builder(
    //               shrinkWrap: true,
    //               itemCount: snapshot.data.length,
    //               itemBuilder: (context, index) {
    //                 return Padding(
    //                   padding: const EdgeInsets.symmetric(horizontal: 12),
    //                   child: Column(
    //                     children: [
    //                       Card(
    //                         color: defaultColors.secondaryColor,
    //                         shape: RoundedRectangleBorder(
    //                             borderRadius: BorderRadius.circular(12)),
    //                         child: InkWell(
    //                           onTap: () {
    //                             GoRouter.of(context).go(
    //                               '/home/ingredients/${widget.categoryName}/recipie/${snapshot.data[index].data()['idMeal']}',
    //                             );
    //                           },
    //                           child: Container(
    //                             padding: const EdgeInsets.all(8),
    //                             child: Row(
    //                               mainAxisAlignment:
    //                                   MainAxisAlignment.spaceBetween,
    //                               children: <Widget>[
    //                                 Flexible(
    //                                   child: Row(
    //                                     children: [
    //                                       Container(
    //                                         width: 100,
    //                                         height: 100,
    //                                         decoration: BoxDecoration(
    //                                             image: DecorationImage(
    //                                                 image: NetworkImage(snapshot
    //                                                         .data[index]
    //                                                         .data()[
    //                                                     'mealPicture'])),
    //                                             borderRadius:
    //                                                 BorderRadius.circular(12),
    //                                             border: Border.all(
    //                                                 color: defaultColors
    //                                                     .primaryColor
    //                                                     .withOpacity(0.5),
    //                                                 style: BorderStyle.solid)),
    //                                       ),
    //                                       Flexible(
    //                                         child: Padding(
    //                                           padding:
    //                                               const EdgeInsets.symmetric(
    //                                                   horizontal: 10),
    //                                           child: Text(
    //                                             snapshot.data[index]
    //                                                     .data()['mealName'] ??
    //                                                 '',
    //                                             style: const TextStyle(
    //                                                 fontSize: 16,
    //                                                 fontWeight:
    //                                                     FontWeight.bold),
    //                                           ),
    //                                         ),
    //                                       ),
    //                                     ],
    //                                   ),
    //                                 ),
    //                                 const Icon(
    //                                   Icons.arrow_forward_ios_rounded,
    //                                   grade: 0.1,
    //                                 ),
    //                               ],
    //                             ),
    //                           ),
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                 );
    //               },
    //             );
    //           }
    //         }));
  }
}
