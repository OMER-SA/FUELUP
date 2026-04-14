import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';

Future<void> changeRecipieDialog(
    BuildContext context, String recipeId, List<Map<String, dynamic>> recipie) {
  DefaultColors defaultColors = DefaultColors();
  List<TextEditingController> controllers = List.generate(
      recipie.length,
      (int index) =>
          TextEditingController(text: recipie[index]['measurement']));

  return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.centerRight,
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close_outlined,
                    color: defaultColors.redColor,
                  ),
                ),
              ),
              AutoHeightGridView(
                  crossAxisCount: recipie.length == 1 ? 1 : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 0,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  shrinkWrap: true,
                  itemCount: controllers.length,
                  builder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: controllers[index],
                        decoration: InputDecoration(
                            label: Text(recipie[index]['ingredient'])),
                      ),
                    );
                  })
            ],
          ),
        );
      });
}

// import 'package:auto_height_grid_view/auto_height_grid_view.dart';
// import 'package:diet_app/utilities/constants.dart';
// import 'package:diet_app/providers/recipie_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// Future<void> changeRecipieDialog(BuildContext context, String recipeId,
//     List<Map<String, Map<String, dynamic>>> recipie) {
//   List<TextEditingController> controllers = List.generate(
//       recipie.length,
//       (index) => TextEditingController(
//           text: recipie[index][recipie[index].keys.first]?['measurement']));

//   DefaultColors defaultColors = DefaultColors();

//   return showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               alignment: Alignment.centerRight,
//               padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//               child: IconButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 icon: Icon(
//                   Icons.close_outlined,
//                   color: defaultColors.redColor,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 alignment: Alignment.center,
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.only(
//                     bottom: MediaQuery.of(context).viewInsets.bottom,
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 25),
//                     child: AutoHeightGridView(
//                       itemCount: recipie.length,
//                       crossAxisCount: 2,
//                       mainAxisSpacing: 10,
//                       crossAxisSpacing: 0,
//                       physics: const BouncingScrollPhysics(),
//                       padding: const EdgeInsets.all(12),
//                       shrinkWrap: true,
//                       builder: (context, index) {
//                         String key = recipie[index].keys.first;
//                         // String value = recipie[index][key]?['measurement'];
//                         Map<String, dynamic>? value = recipie[index][key];

//                         int rowIndex = index % 2;
//                         return Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           decoration: BoxDecoration(
//                               border: rowIndex != 0
//                                   ? Border(
//                                       left: BorderSide(
//                                           color: defaultColors.primaryColor
//                                               .withValues(alpha: 0.3)),
//                                     )
//                                   : null),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 key,
//                                 textAlign: TextAlign.start,
//                                 style: TextStyle(
//                                     color: defaultColors.richBlackColor,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               const SizedBox(
//                                 height: 2,
//                               ),
//                               TextField(
//                                 enabled: value?['isChangeAble'],
//                                 readOnly: !value?['isChangeAble'],
//                                 controller: controllers[index],
//                                 decoration: InputDecoration(
//                                     hintText: value!['isChangeAble']
//                                         ? value['measurement']
//                                         : "${value['measurement']} can not be change",
//                                     contentPadding: const EdgeInsets.symmetric(
//                                         horizontal: 5, vertical: 0)),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   ElevatedButton(
//                     style: ButtonStyle(
//                       backgroundColor:
//                           WidgetStatePropertyAll(defaultColors.primaryColor),
//                     ),
//                     onPressed: () {
//                       context
//                           .read<RecipieProvider>()
//                           .changeRecipie(controllers);
//                       Navigator.pop(context);
//                     },
//                     child: const Text(
//                       'Save',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }
