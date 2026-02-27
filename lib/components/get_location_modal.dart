import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';

Future<void> getLocationModal(BuildContext context) async {
  DefaultColors defaultColors = DefaultColors();
  // await _handleLocationPermission(context);
  return showDialog<void>(
    context: context.mounted ? context : context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text(
          'Are you sure you wanted to Empty this cart?',
        ),
        actions: <Widget>[
          ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(defaultColors.primaryColor)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )),
          ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(defaultColors.redColor)),
              onPressed: () {},
              child: const Text(
                'Delete',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ))
        ],
      );
    },
    );
}

// Future<bool> _handleLocationPermission(BuildContext context) async {
//   bool serviceEnabled;
//   LocationPermission permission;

//   serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   if (!serviceEnabled) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text(
//               'Location services are disabled. Please enable the services')));
//     }

//     return false;
//   }
//   permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Location permissions are denied')));
//       }
//       return false;
//     }
//   }
//   if (permission == LocationPermission.deniedForever) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text(
//               'Location permissions are permanently denied, we cannot request permissions.')));
//     }
//     return false;
//   }
//   return true;
// }
