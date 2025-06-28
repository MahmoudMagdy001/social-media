import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../layout/model/layout_model.dart';
import '../../layout/viewmodel/layout_cubit.dart';
import 'account_setting_state.dart';

class AccountSettingCubit extends Cubit<AccountSettingState> {
  AccountSettingCubit()
      : super(const AccountSettingState(
          status: AccountSettingStatus.initial,
          profileImage: null,
        ));

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  static const String _usersTable = 'users';
  static const String _storageBucket = 'profile-images';

  final formKey = GlobalKey<FormState>();

  // Controllers
  final displayNameController = TextEditingController();
  final emailController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  @override
  Future<void> close() {
    displayNameController.dispose();
    emailController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    return super.close();
  }

  // ============== UI Toggles ==============
  void toggleOldPasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isOldPasswordVisible));
  }

  void toggleNewPasswordVisibility() {
    emit(state.copyWith(
        isConfirmPasswordVisible: !state.isNewConfirmPasswordVisible));
  }

  void resetState() {
    emit(const AccountSettingState(status: AccountSettingStatus.initial));
  }

  // ============== Image Picker ==============
  Future<void> pickProfileImage(BuildContext context) async {
    try {
      emit(state.copyWith(status: AccountSettingStatus.imageLoading));

      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) {
        emit(state.copyWith(status: AccountSettingStatus.initial));
        return;
      }

      final XFile? pickedFile = await ImagePicker()
          .pickImage(source: source, maxHeight: 800, maxWidth: 800)
          .timeout(const Duration(seconds: 20));

      if (pickedFile == null) {
        emit(state.copyWith(
          status: AccountSettingStatus.imageError,
          message: 'No image selected',
        ));
        return;
      }

      final File imageFile = File(pickedFile.path);
      final int fileSize = await imageFile.length();

      if (fileSize > 5 * 1024 * 1024) {
        emit(state.copyWith(
          status: AccountSettingStatus.imageError,
          message: 'Image size should be less than 5MB',
        ));
        return;
      }

      emit(state.copyWith(
        status: AccountSettingStatus.imageSuccess,
        profileImage: imageFile,
        message: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountSettingStatus.imageError,
        message: 'Error selecting image: $e',
      ));
    }
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) {
    return showDialog<ImageSource>(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Image Source',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== Update Profile Info ==============
  Future<void> update({
    String? displayName,
    File? newProfileImage,
    String? oldImageUrl,
    required BuildContext context,
  }) async {
    try {
      emit(state.copyWith(status: AccountSettingStatus.loading));

      String? profileImageUrl;

      if (newProfileImage != null) {
        profileImageUrl = await updateProfileImage(
          newImageFile: newProfileImage,
          userId: _supabase.auth.currentUser!.id,
          oldImageUrl: oldImageUrl,
        );
      }

      if (displayName != null || profileImageUrl != null) {
        await _updateUserProfile(
          uid: _supabase.auth.currentUser!.id,
          displayName: displayName,
          profileImageUrl: profileImageUrl,
        );
      }

      final userData = await _supabase
          .from(_usersTable)
          .select()
          .eq('id', _supabase.auth.currentUser!.id)
          .single();

      final UserModel user = UserModel.fromJson(userData);
      // Refresh LayoutCubit after updating
      if (context.mounted) {
        final layoutCubit = BlocProvider.of<LayoutCubit>(context);
        await layoutCubit.getUser();
      }

      emit(state.copyWith(
        status: AccountSettingStatus.success,
        data: user,
        message: 'Profile updated successfully',
        profileImage: newProfileImage,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountSettingStatus.error,
        message: 'Failed to update profile: $e',
      ));
    }
  }

  Future<void> _updateUserProfile({
    required String uid,
    String? displayName,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (displayName != null) 'display_name': displayName,
      if (profileImageUrl != null) 'profile_image': profileImageUrl,
    };

    await _supabase.from(_usersTable).update(updates).eq('id', uid);
  }

  // ============== Update Password ==============
  Future<void> updatePassword({required String newPassword}) async {
    try {
      emit(state.copyWith(status: AccountSettingStatus.loading));
      await _supabase.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );

      emit(state.copyWith(
        status: AccountSettingStatus.success,
        message: 'Password updated successfully',
      ));
    } on supabase.AuthException catch (e) {
      emit(state.copyWith(
        status: AccountSettingStatus.error,
        message: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountSettingStatus.error,
        message: 'Failed to update password: $e',
      ));
    }
  }

  // ============== Upload Profile Image ==============
  Future<String> updateProfileImage({
    required File newImageFile,
    required String userId,
    String? oldImageUrl,
  }) async {
    try {
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        final oldPath = oldImageUrl
            .split('/storage/v1/object/public/$_storageBucket/')
            .last;
        await _supabase.storage.from(_storageBucket).remove([oldPath]);
      }

      final fileExt = newImageFile.path.split('.').last;
      final fileName =
          'profile_$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      final bytes = await newImageFile.readAsBytes();

      await _supabase.storage.from(_storageBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final imageUrl =
          _supabase.storage.from(_storageBucket).getPublicUrl(filePath);
      return imageUrl;
    } on supabase.StorageException catch (e) {
      throw Exception('Storage error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}
