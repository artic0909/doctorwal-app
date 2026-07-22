import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LocationService {
  static const String _cityCacheKey = 'user_city';
  static const String _isNearMeCacheKey = 'is_near_me';

  /// Synchronous memory cache for fast access
  static bool? _isNearMeMemCache;

  /// Gets the Near Me toggle state
  static Future<bool> getIsNearMe() async {
    if (_isNearMeMemCache != null) return _isNearMeMemCache!;
    final prefs = await SharedPreferences.getInstance();
    _isNearMeMemCache = prefs.getBool(_isNearMeCacheKey) ?? true; // default to true
    return _isNearMeMemCache!;
  }

  /// Sets the Near Me toggle state
  static Future<void> setIsNearMe(bool value) async {
    _isNearMeMemCache = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isNearMeCacheKey, value);
  }

  /// Requests location permission, gets current position, and extracts city.
  /// If [context] is provided, it will enforce location permissions by showing dialogs.
  static Future<String?> getUserCity({BuildContext? context}) async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context != null && context.mounted) {
          bool shouldRetry = await _showLocationRequiredDialog(
            context,
            "Location Services Disabled",
            "Please enable location services in your device settings to view nearby results.",
            () => Geolocator.openLocationSettings(),
          );
          if (!context.mounted) return _getCachedCity();
          if (shouldRetry) {
            // Recursively try again after they return from settings
            return await getUserCity(context: context);
          } else {
            return null; // They chose to skip
          }
        }
        return _getCachedCity();
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context != null && context.mounted) {
            bool shouldRetry = await _showLocationRequiredDialog(
              context,
              "Permission Denied",
              "Location permission is required to find nearby doctors and clinics.",
              () => Geolocator.requestPermission(),
            );
            if (!context.mounted) return _getCachedCity();
            if (shouldRetry) return await getUserCity(context: context);
            return null; // They chose to skip
          }
          return _getCachedCity();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context != null && context.mounted) {
          bool shouldRetry = await _showLocationRequiredDialog(
            context,
            "Permission Denied Forever",
            "Please open app settings and grant location permissions to continue.",
            () => Geolocator.openAppSettings(),
          );
          if (!context.mounted) return _getCachedCity();
          if (shouldRetry) return await getUserCity(context: context);
          return null; // They chose to skip
        }
        return _getCachedCity();
      }

      // When we reach here, permissions are granted and we can continue
      // accessing the position of the device.
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        // Locality usually represents the city
        String? city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
        
        if (city != null && city.isNotEmpty) {
          await _cacheCity(city);
          return city;
        }
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }

    return _getCachedCity();
  }

  static Future<bool> _showLocationRequiredDialog(
    BuildContext context,
    String title,
    String content,
    Future<void> Function() onAction,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false); // Cancel/Skip
              },
              child: const Text("Skip"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext, true); // Try action
              },
              child: const Text("Open Settings", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      await onAction();
      return true;
    }
    return false;
  }

  static Future<void> _cacheCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityCacheKey, city);
  }

  static Future<String?> _getCachedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityCacheKey);
  }
  
  /// Clears the cached city
  static Future<void> clearCachedCity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cityCacheKey);
  }
}
