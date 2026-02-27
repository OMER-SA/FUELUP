// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/http.dart';

// class MealDbService {
//   final String apiBaseURL = 'https://www.themealdb.com/api/json/v1/1';

//   Future<dynamic> getAllCategories() async {
//     String apiEndPoint = 'categories.php';
//     var url = Uri.parse('$apiBaseURL/$apiEndPoint');

//     try {
//       Response response = await http.get(url);

//       if (response.statusCode == 200) {
//         var jsonResponse = jsonDecode(response.body);
//         return jsonResponse;
//       } else {
//         if (kDebugMode) {
//           print('Request failed with status: ${response.statusCode}');
//         }
//         return null;
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error: $e');
//       }
//       return null;
//     }
//   }

//   Future<dynamic> findByCategory(String category) async {
//     var url = Uri.parse('$apiBaseURL/filter.php?c=$category');
//     try {
//       Response response = await http.get(url);

//       if (response.statusCode == 200) {
//         var jsonResponse = jsonDecode(response.body);
//         return jsonResponse;
//       } else {
//         if (kDebugMode) {
//           print('Request failed with status: ${response.statusCode}');
//         }
//         return null;
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error: $e');
//       }
//       return null;
//     }
//   }

//   Future<dynamic> getRecipie(dynamic mealId) async {
//     print(mealId);
//     var url = Uri.parse('$apiBaseURL/lookup.php?i=$mealId');
//     try {
//       Response response = await http.get(url);

//       if (response.statusCode == 200) {
//         var jsonResponse = jsonDecode(response.body);
//         return jsonResponse;
//       } else {
//         if (kDebugMode) {
//           print('Request failed with status: ${response.statusCode}');
//         }
//         return null;
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error: $e');
//       }
//       return null;
//     }
//   }
// }
