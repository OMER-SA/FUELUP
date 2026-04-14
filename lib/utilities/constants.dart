import 'package:flutter/material.dart';

class DefaultColors {
  Color richBlackColor = const Color(0xFF353535);
  Color primaryColor = const Color(0xFF344E41);
  Color secondaryColor = const Color(0xFFDAD7CD);
  Color lightGreenColor = const Color(0xFF588157);
  Color maroonColor = const Color(0xFF78290F);
  Color redColor = const Color(0xFFD62828);
  Color greyColor = const Color(0xFF9E9E9E);
  Color warningColor = const Color(0xFFf48c06);
}

class CommonAllergies {
  static List<String> intolerances = [
    "Corn",
    "Dairy",
    "Eggs",
    "Fish",
    "Gluten",
    "Lupin",
    "Mustard",
    "Nuts",
    "Peanuts",
    "Sesame",
    "Shellfish",
    "Soy",
    "Sulfites",
    "Wheat"
  ];

  static List<Map<String, dynamic>> allergies = intolerances.map((item) {
    return {"name": item, "isSelected": false};
  }).toList();

  static List<String> outputAllergies = [
    "Barley",
    "Casein",
    "Corn starch",
    "Corn syrup",
    "Crustaceans",
    "Egg whites",
    "Egg yolks",
    "Fish oils",
    "Fish proteins",
    "Gluten",
    "Lactose",
    "Lupin flour",
    "Lupin proteins",
    "Milk proteins",
    "Mollusks",
    "Mustard oil",
    "Mustard seeds",
    "Nut oils",
    "Oats",
    "Peanut oil",
    "Peanut protein",
    "Rye",
    "Sesame oil",
    "Sesame seeds",
    "Soy protein",
    "Sulfite preservatives",
    "Sulfur dioxide",
    "Tofu",
    "Tree nuts",
    "Wheat",
    "Wheat protein"
  ];
}

class MealCategories {
  static List<DropdownMenuItem> categories = const <DropdownMenuItem>[
    DropdownMenuItem(
      value: "No Category Selected",
      child: Text("No Category Selected"),
    ),
    DropdownMenuItem(
      value: "italian",
      child: Text("Italian"),
    ),
    DropdownMenuItem(
      value: "asian",
      child: Text("Asian"),
    ),
    DropdownMenuItem(
      value: "mexican",
      child: Text("Mexican"),
    ),
    DropdownMenuItem(
      value: "breakfast",
      child: Text("Breakfast"),
    ),
  ];
}
