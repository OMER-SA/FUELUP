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
    // DropdownMenuItem(
    //   value: "seafood",
    //   child: Text("Seafood"),
    // ),
    // DropdownMenuItem(
    //   value: "side",
    //   child: Text("Side"),
    // ),
    // DropdownMenuItem(
    //   value: "starter",
    //   child: Text("Starter"),
    // ),
    // DropdownMenuItem(
    //   value: "vegan",
    //   child: Text("Vegan"),
    // ),
    // DropdownMenuItem(
    //   value: "vegetarian",
    //   child: Text("Vegetarian"),
    // ),
    // DropdownMenuItem(
    //   value: "breakfast",
    //   child: Text("Breakfast"),
    // ),
    // DropdownMenuItem(
    //   value: "goat",
    //   child: Text("Goat"),
    // ),
  ];
}



// Future<Interpreter> downloadAndLoadModel() async {
//   // Download the custom model
//   final model = await FirebaseModelDownloader.instance.getModel(
//     "dietApp", // Your model name
//     FirebaseModelDownloadType.localModel,
//     FirebaseModelDownloadConditions(androidWifiRequired: true),
//   );

//   // Load the model from the model's local file path
//   final interpreter = Interpreter.fromFile(model.file);

//   return interpreter;

//   // You can now use the interpreter for predictions
//   // Example usage for inference will go here
// }

// Future<List<String>> predictIntolerances(
//     List<String> allergies, double bmi) async {
//   // Ensure the model is downloaded and loaded
//   final interpreter = await downloadAndLoadModel();

//   // Preprocess allergies and BMI (implement encoding logic here)
//   final allergiesEncoded = encodeAllergies(allergies);

//   // Prepare input features (combine allergies and BMI)
//   List<List<double>> input = [
//     allergiesEncoded + [bmi]
//   ];

//   // Update the output buffer to match the model's output shape
//   // The model's output shape is [1, 31], so the output buffer should have the same shape
//   var output = List.filled(31, 0.0).reshape([1, 31]);

//   // Run inference
//   interpreter.run(input, output);

//   // Decode the intolerances (binary output vector to list of intolerances)
//   final predictedIntolerances = decodeIntolerances(output[0]);
//   print("Interpretter: $predictedIntolerances");

//   return predictedIntolerances;
// }

// Future<List<String>> predictIntolerances(
//     List<String> allergies, double bmi) async {
//   // Ensure the model is downloaded and loaded
//   final interpreter = await downloadAndLoadModel();

//   // Preprocess allergies and BMI (implement encoding logic here, similar to Python's MultiLabelBinarizer)
//   final allergiesEncoded =
//       encodeAllergies(allergies); // You'll have to implement this function

//   // Prepare input features (combine allergies and BMI)
//   List<List<double>> input = [
//     allergiesEncoded + [bmi]
//   ]; // Ensure the shape is correct for the model

//   // Prepare output buffer for results (size should match number of intolerances)
//   var output = List.filled(allergies.length, 0).reshape([1, allergies.length]);

//   // Run inference

//   interpreter.run(input, output);

//   // Decode the intolerances (similar to inverse transform in Python)
//   final predictedIntolerances = decodeIntolerances(output[0]);

//   print(
//       "predictedIntolerances: $predictedIntolerances"); // Implement decoding logic

//   return predictedIntolerances;
// }

// List<double> encodeAllergies(List<String> allergies) {
//   // List of all possible allergies used during model training
//   List<String> allPossibleAllergies = [
//     'Dairy',
//     'Nuts',
//     'Gluten',
//     'Shellfish',
//     'Soy',
//     'Eggs',
//     'Peanuts',
//     'Fish',
//     'Wheat',
//     'Sesame',
//     'Corn',
//     'Mustard',
//     'Sulfites',
//     'Lupin'
//   ];

//   // Initialize a vector with zeros for all possible allergies
//   List<double> encodedAllergies = List.filled(allPossibleAllergies.length, 0.0);

//   // Set 1.0 for each allergy present in the input
//   for (var allergy in allergies) {
//     int index = allPossibleAllergies.indexOf(allergy);
//     if (index != -1) {
//       encodedAllergies[index] = 1.0;
//     }
//   }

//   return encodedAllergies;
// }

// List<String> decodeIntolerances(List<double> predictedIntolerances) {
//   // List of all possible intolerances used during model training
//   List<String> allPossibleIntolerances = [
//     'Dairy',
//     'Nuts',
//     'Gluten',
//     'Shellfish',
//     'Soy',
//     'Eggs',
//     'Peanuts',
//     'Fish',
//     'Wheat',
//     'Sesame',
//     'Corn',
//     'Mustard',
//     'Sulfites',
//     'Lupin'
//   ];

//   // Initialize a list to hold the predicted intolerances
//   List<String> intolerances = [];

//   // Map the binary prediction back to the intolerances
//   for (int i = 0; i < predictedIntolerances.length; i++) {
//     if (predictedIntolerances[i] == 1.0) {
//       intolerances.add(allPossibleIntolerances[i]);
//     }
//   }

//   return intolerances;
// }
