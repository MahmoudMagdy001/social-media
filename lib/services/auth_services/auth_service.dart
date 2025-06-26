// ignore_for_file: unnecessary_null_comparison

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthService {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  static const String _storageBucket = 'profile-images';

  static const String _usersTable = 'users';

  Future<Map<String, dynamic>> updateUserProfile({
    String? displayName,
    File? newProfileImage,
    String? oldImageUrl,
  }) async {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) {
      throw Exception('User not logged in. Cannot update profile.');
    }

    try {
      String? profileImageUrl;
      if (newProfileImage != null) {
        profileImageUrl = await updateProfileImage(
            newImageFile: newProfileImage,
            userId: supabaseUser.id,
            oldImageUrl: oldImageUrl);
      }

      if (displayName != null || profileImageUrl != null) {
        await _updateUserProfile(
          uid: supabaseUser.id,
          displayName: displayName,
          profileImageUrl: profileImageUrl,
        );
      }

      // Fetch updated user data from the database
      final userData = await _supabase
          .from(_usersTable)
          .select()
          .eq('id', supabaseUser.id)
          .single();

      return userData;
    } on supabase.AuthException catch (e) {
      _handleAuthException(e, 'update profile');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error updating profile: $e');
      rethrow;
    }
  }

  Future<void> _updateUserProfile({
    required String uid,
    String? displayName,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updates['display_name'] = displayName;
        await _supabase
            .from(_usersTable)
            .update({'display_name': displayName}).eq('id', uid);
      }
      if (profileImageUrl != null) {
        updates['profile_image'] = profileImageUrl;
        await _supabase
            .from(_usersTable)
            .update({'profile_image': profileImageUrl}).eq('id', uid);
      }

      await _supabase.from(_usersTable).update(updates).eq('id', uid);
    } catch (e) {
      throw Exception('Unexpected error while updating user profile: $e');
    }
  }

  Future<void> updatePassword({
    required String newPassword,
  }) async {
    try {
      if (newPassword != null && newPassword.isNotEmpty) {
        await _supabase.auth.updateUser(
          supabase.UserAttributes(password: newPassword),
        );
      }
    } on supabase.AuthException catch (e) {
      _handleAuthException(e, 'update password');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error updating password: $e');
      rethrow;
    }
  }

  Future<String> updateProfileImage({
    required File newImageFile,
    required String userId,
    String? oldImageUrl,
  }) async {
    try {
      // Delete the old image if provided
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        final oldPath = oldImageUrl
            .split('/storage/v1/object/public/$_storageBucket/')
            .last;

        debugPrint('Deleting old image at path: $oldPath');

        await _supabase.storage.from(_storageBucket).remove([oldPath]);
        debugPrint('Old profile image deleted.');
      }

      // Prepare file info
      final fileExt = newImageFile.path.split('.').last;
      final fileName =
          'profile_$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      debugPrint('Uploading new profile image to path: $filePath');

      // Read image bytes
      final bytes = await newImageFile.readAsBytes();

      // Upload new image
      await _supabase.storage.from(_storageBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get the public URL
      final imageUrl =
          _supabase.storage.from(_storageBucket).getPublicUrl(filePath);
      debugPrint('New profile image uploaded. URL: $imageUrl');

      return imageUrl;
    } on supabase.StorageException catch (e) {
      debugPrint('Supabase storage error: ${e.message}');
      throw Exception('Failed to update profile image: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error updating profile image: $e');
      rethrow;
    }
  }

  void _handleAuthException(supabase.AuthException e, String operation) {
    debugPrint('Auth Exception during $operation: ${e.message}');

    switch (e.message) {
      case 'Invalid login credentials':
        throw Exception('Invalid email or password.');
      case 'Email not confirmed':
        throw Exception('Please confirm your email address.');
      case 'Email already registered':
        throw Exception('This email is already registered.');
      case 'Password should be at least 6 characters':
        throw Exception('The password is too weak.');
      case 'Invalid email':
        throw Exception('The email address is invalid.');
      case 'User not found':
        throw Exception('No user found with this email.');
      case 'Too many requests':
        throw Exception(
            'Too many attempts. Please wait a moment and try again.');
      case String message when message.contains('For security purposes'):
        final seconds = int.tryParse(message
                .split(' ')
                .lastWhere((word) => word.contains('seconds'))
                .replaceAll('seconds', '')
                .trim()) ??
            48;
        throw Exception('Please wait $seconds seconds before trying again.');
      default:
        throw Exception('Authentication error: ${e.message}');
    }
  }
}
