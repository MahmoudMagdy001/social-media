import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/core/widgets/custom_icon_button.dart';
import 'package:facebook_clone/core/widgets/custom_text.dart';
import 'package:facebook_clone/core/widgets/custom_text_field.dart';
import 'package:facebook_clone/features/account_setting/viewmodel/account_setting_cubit.dart';
import 'package:facebook_clone/features/account_setting/viewmodel/account_setting_state.dart';
import 'package:facebook_clone/features/layout/model/layout_model.dart';

class AccountSettingView extends StatelessWidget {
  final UserModel user;
  const AccountSettingView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountSettingCubit()
        ..displayNameController.text = user.displayName
        ..emailController.text = user.email,
      child: Scaffold(
        appBar: AppBar(
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
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<AccountSettingCubit, AccountSettingState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              if (state.status == AccountSettingStatus.success) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Success'),
                    content: const Text('Profile updated successfully.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else if (state.status == AccountSettingStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message ?? 'An error occurred')),
                );
              }
            },
            builder: (context, state) {
              final cubit = context.read<AccountSettingCubit>();

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 120,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: state.profileImage != null
                                ? FileImage(state.profileImage!)
                                : (user.profileImage.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        user.profileImage)
                                    : null) as ImageProvider?,
                            child: (state.profileImage == null &&
                                    user.profileImage.isEmpty)
                                ? Icon(Icons.person,
                                    size: 120, color: Colors.grey[600])
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
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white),
                                onPressed: () =>
                                    cubit.pickProfileImage(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: cubit.displayNameController,
                      labelText: 'Display Name',
                    ),
                    const SizedBox(height: 25),
                    CustomTextField(
                      labelText: 'E-mail',
                      prefixIcon: Icons.email,
                      controller: cubit.emailController,
                      enabled: false,
                    ),
                    const SizedBox(height: 20),
                    const CustomText(
                      'Update Password',
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      prefixIcon: Icons.lock,
                      obscureText: true,
                      controller: cubit.oldPasswordController,
                      labelText: 'Old Password',
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      prefixIcon: Icons.lock_reset,
                      controller: cubit.newPasswordController,
                      obscureText: !state.isOldPasswordVisible,
                      labelText: 'New Password',
                      suffixIcon: state.isOldPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      onSuffixIconTap: () =>
                          cubit.toggleOldPasswordVisibility(),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.status ==
                                  AccountSettingStatus.loading
                              ? null
                              : () async {
                                  final trimmedDisplayName =
                                      cubit.displayNameController.text.trim();
                                  final newPassword =
                                      cubit.newPasswordController.text.trim();
                                  final isDisplayNameChanged =
                                      trimmedDisplayName != user.displayName;
                                  final isProfileImageChanged =
                                      state.profileImage != null;

                                  if (isDisplayNameChanged ||
                                      isProfileImageChanged) {
                                    await cubit.update(
                                      displayName: trimmedDisplayName,
                                      newProfileImage: state.profileImage,
                                      oldImageUrl: user.profileImage,
                                      context: context,
                                    );
                                  }

                                  if (newPassword.isNotEmpty) {
                                    await cubit.updatePassword(
                                        newPassword: newPassword);
                                  }

                                  if (!isDisplayNameChanged &&
                                      !isProfileImageChanged &&
                                      newPassword.isEmpty) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Center(
                                            child: Text(
                                              'No changes made!',
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: state.status == AccountSettingStatus.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
