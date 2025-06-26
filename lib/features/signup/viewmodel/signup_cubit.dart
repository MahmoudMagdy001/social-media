import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit()
      : super(const SignupState(
          status: SignupStatus.initial,
          profileImage: null,
        ));

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  static const String _storageBucket = 'profile-images';
  static const String _usersTable = 'users';

  // Form State
  final formKey = GlobalKey<FormState>();

  // Controllers
  final displayNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Future<void> close() {
    displayNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    return super.close();
  }

  // ============================ IMAGE PICKING ============================

  Future<void> pickProfileImage(BuildContext context) async {
    try {
      emit(state.copyWith(status: SignupStatus.imageLoading));

      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) {
        emit(state.copyWith(status: SignupStatus.initial));
        return;
      }

      final XFile? pickedFile = await ImagePicker()
          .pickImage(source: source, maxHeight: 800, maxWidth: 800)
          .timeout(const Duration(seconds: 20),
              onTimeout: () =>
                  throw TimeoutException('Image picker timed out'));

      if (pickedFile == null) {
        emit(state.copyWith(
          status: SignupStatus.imageError,
          message: 'No image selected',
        ));
        return;
      }

      final File imageFile = File(pickedFile.path);
      final int fileSize = await imageFile.length();

      if (fileSize > 5 * 1024 * 1024) {
        emit(state.copyWith(
          status: SignupStatus.imageError,
          message: 'Image size should be less than 5MB',
        ));
        return;
      }

      emit(state.copyWith(
        status: SignupStatus.imageSuccess,
        profileImage: imageFile,
        message: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SignupStatus.imageError,
        message: 'Error selecting image: ${e.toString()}',
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

  // ============================ SIGNUP ============================

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    File? profileImage,
  }) async {
    try {
      emit(state.copyWith(status: SignupStatus.loading));

      final response =
          await _supabase.auth.signUp(email: email, password: password);
      final user = response.user;

      if (user == null) {
        emit(state.copyWith(
            status: SignupStatus.error,
            message: 'Failed to create user account'));
        return;
      }

      await Future.delayed(const Duration(seconds: 1));

      String? profileImageUrl;
      if (profileImage != null) {
        profileImageUrl = await _uploadProfileImage(profileImage, user.id);
        if (profileImageUrl == null) {
          emit(state.copyWith(
              status: SignupStatus.error,
              message: 'Failed to upload profile image'));
          return;
        }
      }

      final userData = {
        'id': user.id,
        'email': email,
        'display_name': displayName,
        'profile_image': profileImageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(_usersTable).insert(userData);
      emit(state.copyWith(status: SignupStatus.success, data: userData));
    } on supabase.AuthException catch (e) {
      _handleAuthException(e, 'sign up');
    } catch (e) {
      emit(state.copyWith(
          status: SignupStatus.error,
          message: 'An unexpected error occurred.'));
    }
  }

  Future<String?> _uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.$fileExt';
      final filePath = '$userId/$fileName';

      final bytes = await imageFile.readAsBytes();

      await _supabase.storage.from(_storageBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return _supabase.storage.from(_storageBucket).getPublicUrl(filePath);
    } catch (e) {
      emit(state.copyWith(
        status: SignupStatus.imageError,
        message: 'Error uploading profile image.',
      ));
      return null;
    }
  }

  void _handleAuthException(supabase.AuthException e, String operation) {
    final msg = e.message;

    if (msg.contains('Email already registered')) {
      emit(state.copyWith(
        status: SignupStatus.error,
        message: 'This email is already registered.',
      ));
    } else if (msg.contains('Invalid email')) {
      emit(state.copyWith(
        status: SignupStatus.error,
        message: 'The email address is invalid.',
      ));
    } else {
      emit(state.copyWith(status: SignupStatus.error, message: msg));
    }
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(
        isConfirmPasswordVisible: !state.isConfirmPasswordVisible));
  }
}
