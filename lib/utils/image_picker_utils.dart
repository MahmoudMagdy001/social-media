import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 600,
        maxWidth: 600,
      );
      if (image == null) return null;
      debugPrint('Picked image path: ${image.path}');
      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  static Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(seconds: 30),
      );
      if (video == null) return null;
      debugPrint('Picked video path: ${video.path}');
      return File(video.path);
    } catch (e) {
      debugPrint('Error picking video from gallery: $e');
      return null;
    }
  }

  /// Picks an image from the camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 600,
        maxWidth: 600,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  static Future<File?> pickvideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: 30),
      );
      if (video == null) return null;
      return File(video.path);
    } catch (e) {
      debugPrint('Error picking video from camera: $e');
      return null;
    }
  }
}
