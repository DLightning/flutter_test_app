import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/model/photo.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoController {
  Future<void> savePhoto(Photo photo, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      List<String> data = prefs.getStringList(userId) ?? [];

      data.add(jsonEncode({
        'id': photo.id,
        'name': photo.name,
        'description': photo.description,
        'rating': photo.rating,
        'imagePath': photo.imagePath,
        'latitude': photo.latitude,
        'longitude': photo.longitude,
        'timestamp': photo.timestamp.toIso8601String(),
      }));

      await prefs.setStringList(userId, data);
    } catch (e) {
      print('Error saving photo: $e');
    }
  }

  Future<List<Photo>> getUserPhotos(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> data = prefs.getStringList(userId) ?? [];

      final List<Photo> userPhotos = data.map((jsonString) {
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        return Photo(
          id: jsonData['id'],
          name: jsonData['name'],
          description: jsonData['description'],
          rating: jsonData['rating'],
          imagePath: jsonData['imagePath'],
          latitude: jsonData['latitude'],
          longitude: jsonData['longitude'],
          timestamp: DateTime.parse(jsonData['timestamp']),
        );
      }).toList();

      return userPhotos;
    } catch (e) {
      print('Error loading user photos: $e');
    }

    return [];
  }

  Future<Position> determineCustomPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitudeAccuracy: 0,
        altitude: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  Future<void> updatePhoto(Photo updatedPhoto, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> data = prefs.getStringList(userId) ?? [];

      final String updatedPhotoId = updatedPhoto.id;
      final int index = data.indexWhere((jsonPhoto) {
        final existingPhoto = Photo.fromJson(json.decode(jsonPhoto));
        return existingPhoto.id == updatedPhotoId;
      });

      if (index != -1) {
        final Map<String, dynamic> jsonPhoto = json.decode(data[index]);
        jsonPhoto['name'] = updatedPhoto.name;
        jsonPhoto['description'] = updatedPhoto.description;
        jsonPhoto['rating'] = updatedPhoto.rating;

        data[index] = json.encode(jsonPhoto);

        await prefs.setStringList(userId, data);
      } else {
        print('Photo not found for update: $updatedPhotoId');
      }
    } catch (e) {
      print('Error updating photo: $e');
    }
  }

  Future<void> deletePhoto(String photoId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> data = prefs.getStringList(userId) ?? [];

      data.removeWhere((jsonPhoto) {
        final existingPhoto = Photo.fromJson(json.decode(jsonPhoto));
        return existingPhoto.id == photoId;
      });

      await prefs.setStringList(userId, data);
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty && placemarks[0].locality != null) {
        String place =
            '${placemarks[0].subAdministrativeArea.toString()}, ${placemarks[0].country.toString()}';
        return place;
      } else {
        return 'Unknown';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location name: $e');
      }
      return 'Unknown';
    }
  }
}
