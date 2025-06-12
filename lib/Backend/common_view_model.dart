import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../global/global_vars.dart';

class CommonViewModel {



  Future<String> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users to enable the location services.
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30), // Add timeout
      );
      position = cPosition;

      placeMark = await placemarkFromCoordinates(
          cPosition.latitude,
          cPosition.longitude
      );

      if (placeMark != null && placeMark!.isNotEmpty) {
        Placemark placeMarkVar = placeMark![0];
        fullAddress = "${placeMarkVar.subThoroughfare ?? ''} ${placeMarkVar.thoroughfare ?? ''}, ${placeMarkVar.subLocality ?? ''} ${placeMarkVar.locality ?? ''}, ${placeMarkVar.subAdministrativeArea ?? ''}, ${placeMarkVar.administrativeArea ?? ''} ${placeMarkVar.postalCode ?? ''}, ${placeMarkVar.country ?? ''}";

        // Clean up the address by removing extra spaces and commas
        fullAddress = fullAddress
            .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
            .replaceAll(RegExp(r',\s*,'), ',') // Remove double commas
            .replaceAll(RegExp(r'^,\s*|,\s*$'), '') // Remove leading/trailing commas
            .trim();

        return fullAddress;
      } else {
        throw Exception('Unable to get address from coordinates');
      }
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }




  void showSnackBar(String message, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 243, 138, 33),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'OK',
        textColor: const Color.fromARGB(255, 0, 0, 0),
        onPressed: () {},
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      elevation: 10, // Elevation for shadow
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


}