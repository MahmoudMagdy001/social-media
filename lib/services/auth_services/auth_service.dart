// ignore_for_file: unnecessary_null_comparison

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthService {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  static const String _storageBucket = 'profile-images';

  static const String _usersTable = 'users';

  Future<Map<String, dynamic>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    File? profileImage,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user == null) {
          throw Exception('Failed to create user account');
        }

        // Wait for the session to be established
        await Future.delayed(const Duration(seconds: 1));

        // Upload profile image if provided
        String? profileImageUrl;
        if (profileImage != null) {
          profileImageUrl = await _uploadProfileImage(
            profileImage,
            response.user!.id,
          );
        }

        // Create user record with profile image
        final userData = {
          'id': response.user!.id,
          'email': email,
          'display_name': displayName,
          'profile_image': profileImageUrl,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _supabase.from(_usersTable).insert(userData);

        return userData;
      } on supabase.AuthException catch (e) {
        if (e.message.contains('For security purposes') &&
            retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(retryDelay * retryCount);
          continue;
        }
        _handleAuthException(e, 'sign up');
        rethrow;
      } catch (e) {
        debugPrint('Unexpected error during sign up: $e');
        rethrow;
      }
    }
    throw Exception('Maximum retry attempts reached. Please try again later.');
  }

  Future<String> _uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'profile_$userId.$fileExt';
      final filePath = '$userId/$fileName';

      debugPrint('Uploading profile image to path: $filePath');

      // Read image as bytes
      final bytes = await imageFile.readAsBytes();

      // Upload image to Supabase Storage
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

      debugPrint('Profile image uploaded successfully. URL: $imageUrl');
      return imageUrl;
    } on supabase.StorageException catch (e) {
      debugPrint('Storage error uploading profile image: ${e.message}');
      if (e.message.contains('row-level security policy')) {
        throw Exception(
            'Unable to upload profile image. Please make sure you have the correct permissions and the storage bucket is properly configured.');
      }
      rethrow;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to sign in');
      }

      // Fetch complete user data from users table
      final userData = await _supabase
          .from(_usersTable)
          .select()
          .eq('id', response.user!.id)
          .single();

      debugPrint('User profile image URL: ${userData['profile_image']}');
      debugPrint('Complete user data: $userData');
      return userData;
    } on supabase.AuthException catch (e) {
      _handleAuthException(e, 'sign in');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

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
