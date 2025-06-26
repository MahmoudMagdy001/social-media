import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:facebook_clone/services/auth_services/auth_service.dart';
import 'package:facebook_clone/core/widgets/custom_button.dart';
import 'package:facebook_clone/core/widgets/custom_icon_button.dart';
import 'package:facebook_clone/core/widgets/custom_text.dart';
import 'package:facebook_clone/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:facebook_clone/core/utlis/image_picker_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AccountSetting extends StatefulWidget {
  const AccountSetting({
    super.key,
  });

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final AuthService authService = AuthService();

  bool _isInitialLoading = true;
  bool _obscureText = true;
  String? _errorMessage;
  String? currentProfileImage;
  bool updateLoading = false;
  File? newProfileImage;
  ImageProvider<Object>? imageProvider;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  final supabase.User currentUser =
      supabase.Supabase.instance.client.auth.currentUser!;

  Future<void> _initializeControllers() async {
    try {
      final userData = await supabase.Supabase.instance.client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();
      setState(() {
        _displayNameController.text = userData['display_name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        currentProfileImage = userData['profile_image'] ?? '';
        debugPrint('currentProfileImage: $currentProfileImage');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _oldPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final File? imageFile = await ImagePickerUtils.pickImageFromGallery();
      if (imageFile != null) {
        setState(() {
          newProfileImage = imageFile;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Widget _buildProfileImage() {
    if (newProfileImage != null) {
      imageProvider = FileImage(newProfileImage!);
    } else if (currentProfileImage != null && currentProfileImage!.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(currentProfileImage!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 120,
            backgroundColor: Colors.grey[200],
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.person, size: 120, color: Colors.grey[600])
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _pickProfileImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayNameField() {
    return CustomTextField(
      controller: _displayNameController,
      labelText: 'Display Name',
      onChanged: (value) {
        setState(() {
          _displayNameController.text = value;
        });
      },
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      prefixIcon: Icons.email,
      controller: _emailController,
      labelText: 'E-mail',
      enabled: false,
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomText('Update Password'),
        const SizedBox(height: 15),
        CustomTextField(
          prefixIcon: Icons.lock,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          controller: _oldPasswordController,
          labelText: 'Please enter your old password',
        ),
        const SizedBox(height: 15),
        CustomTextField(
          prefixIcon: Icons.lock_reset,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          controller: _passwordController,
          labelText: 'New Password',
          suffixIcon: _obscureText ? Icons.visibility : Icons.visibility_off,
          onSuffixIconTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ],
    );
  }

  Widget _buildShimmerProfileImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CircleAvatar(
        radius: 120,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildShimmerTextField() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Scaffold(
      appBar: appBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildShimmerProfileImage(),
              const SizedBox(height: 20),
              _buildShimmerTextField(),
              const SizedBox(height: 25),
              _buildShimmerTextField(),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildShimmerTextField(),
                  const SizedBox(height: 15),
                  _buildShimmerTextField(),
                ],
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: CustomButton(
                  onPressed: () {},
                  text: 'Update',
                  style: const ButtonStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            updateLoading = true;
          });
          await authService.updateUserProfile(
            displayName: _displayNameController.text.trim(),
            newProfileImage: newProfileImage,
            oldImageUrl: currentProfileImage,
          );

          await authService.updatePassword(
            newPassword: _passwordController.text.trim(),
          );
          setState(() {
            updateLoading = false;
          });
          if (mounted) {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Success'),
                    content:
                        Text('Your profile has been updated successfully.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                });
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: updateLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: Center(
                    child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4,
                )),
              )
            : Text('Update'),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CustomIconButton(
              onPressed: () => Navigator.of(context).pop(),
              iconData: Icons.arrow_back_ios_new,
            ),
            const SizedBox(width: 10),
            const CustomText(
              'Account Setting',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return _buildShimmerLoading();
    }

    return Scaffold(
      appBar: appBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildProfileImage(),
              const SizedBox(height: 20),
              _buildDisplayNameField(),
              const SizedBox(height: 25),
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordFields(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 25),
              _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }
}
