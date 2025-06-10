import 'package:facebook_clone/widgets/custom_button.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:facebook_clone/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_services/auth_service.dart';
import '../../utils/image_picker_utils.dart';
import 'login_screen.dart';

/// A screen that handles user registration functionality.
class SignupScreen extends StatefulWidget {
  final AuthService authService;

  const SignupScreen({
    super.key,
    required this.authService,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isImageUploading = false;
  String? _errorMessage;
  File? _profileImage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Shows a dialog to select image source (camera or gallery)
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  /// Handles profile image selection
  Future<void> _pickProfileImage() async {
    try {
      setState(() {
        _isImageUploading = true;
      });

      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) {
        setState(() {
          _isImageUploading = false;
        });
        return;
      }

      File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await ImagePickerUtils.pickImageFromCamera();
      } else {
        imageFile = await ImagePickerUtils.pickImageFromGallery();
      }

      if (imageFile == null) {
        setState(() {
          _isImageUploading = false;
        });
        return;
      }

      final int fileSize = await imageFile.length();

      if (fileSize > 5 * 1024 * 1024) {
        // 5MB limit
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image size should be less than 5MB'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isImageUploading = false;
        });
        return;
      }

      setState(() {
        _profileImage = imageFile;
        _isImageUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isImageUploading = false;
      });
    }
  }

  /// Validates the display name input
  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Display name is optional
    }
    if (value.length > 50) {
      return 'Display name must be less than 50 characters';
    }
    return null;
  }

  /// Validates the email input
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates the password input
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates the confirm password input
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Handles the sign up process
  Future<void> _performSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim()
            : null,
        profileImage: _profileImage,
      );

      if (!mounted) return;

      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Shows success message after successful signup

  /// Navigates to the login screen
  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(authService: widget.authService),
      ),
    );
  }

  /// Builds the profile image selection widget
  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: _isImageUploading ? null : _pickProfileImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        child: _isImageUploading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _profileImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(
                      _profileImage!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  /// Builds the form fields
  Widget _buildFormFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _displayNameController,
          labelText: 'Display Name (Optional)',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          validator: _validateDisplayName,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          prefixIcon: Icons.email_outlined,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          labelText: 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          validator: _validatePassword,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          prefixIcon: Icons.lock_outline,
          controller: _confirmPasswordController,
          labelText: 'Confirm Password',
          obscureText: true,
          validator: _validateConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _isLoading ? null : _performSignUp(),
        ),
      ],
    );
  }

  /// Builds the error message widget
  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        _errorMessage!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds the action buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomButton(onPressed: _performSignUp, text: 'Sign Up'),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _isLoading ? null : _navigateToLogin,
          child: const Text('Already have an account? Log In'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const CustomText(
                  'Create your Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Center(child: _buildProfileImagePicker()),
                const SizedBox(height: 30),
                _buildFormFields(),
                const SizedBox(height: 24),
                _buildErrorMessage(),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
