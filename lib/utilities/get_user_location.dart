import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

Future<Position> getUserLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    return Future.error('Location service are disabled');
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error("Location Permissions are Denied");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        "Location permissions are permanently denied, we cannot request permissions.");
  }

  Position position = await Geolocator.getCurrentPosition()
      .timeout(Duration(seconds: 10), onTimeout: () {
    throw TimeoutException("Could not get location");
  });

  return position;
}

Future<List<Placemark>> getLocationPlacemark(
    {required double longitude, required double latitude}) async {
  List<Placemark> placeMarks =
      await placemarkFromCoordinates(latitude, longitude);
  return placeMarks;
}

Future<String> getUserAddress() async {
  try {
    final Position cordinates = await getUserLocation()
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw TimeoutException("Could not get location - timed out");
    });
    final List<Placemark> placeMarks = await getLocationPlacemark(
            longitude: cordinates.longitude, latitude: cordinates.latitude)
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw TimeoutException("Could not get address from location");
    });

    if (placeMarks.isEmpty) {
      return '';
    }

    final Placemark place = placeMarks[0];
    final String street = place.street ?? '';
    final String subLocality = place.subLocality ?? '';
    final String locality = place.locality ?? '';
    final String administrativeArea = place.administrativeArea ?? '';
    final String country = place.country ?? '';

    // Constructing the full address with proper formatting
    final List<String> addressParts = [
      if (street.isNotEmpty) street,
      if (subLocality.isNotEmpty) subLocality,
      if (locality.isNotEmpty) locality,
      if (administrativeArea.isNotEmpty) administrativeArea,
      if (country.isNotEmpty) country,
    ];

    final String address = addressParts.join(', ');
    return address;
  } catch (e) {
    debugPrint('Error getting user address: $e');
    return ''; // Return empty string on error so the user can enter manually
  }
}

Future getCordinatesFromAddress({required String address}) async {
  List<Location> locations = await locationFromAddress(address);
  if (locations.isNotEmpty) {
    Location cordinates = locations[0];
    return {'longitude': cordinates.longitude, 'latitude': cordinates.latitude};
  }
  return null;
}
