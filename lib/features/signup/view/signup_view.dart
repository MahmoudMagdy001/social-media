import 'dart:io';

import 'package:facebook_clone/features/signin/view/signin_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/custom_text.dart';
import '../../menu/viewmodel/theme_cubit.dart';
import '../../menu/viewmodel/theme_state.dart';
import '../viewmodel/signup_cubit.dart';
import '../viewmodel/signup_state.dart';
import 'widgets/user_image.dart';
import 'widgets/user_info.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SigninView(),
      ),
    );
  }

  void _showDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onOk,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dialog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, __, ___) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack);

        return ScaleTransition(
          scale: curved,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            titlePadding: const EdgeInsets.only(top: 20),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(10),
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOk?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 2,
                ),
                child: const Text("OK", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackbar({
    required BuildContext context,
    required String message,
    required bool success,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
            child: CustomText(
          message,
          style: TextStyle(fontSize: 16, color: Colors.white),
        )),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupCubit(),
      child: BlocConsumer<SignupCubit, SignupState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == SignupStatus.error) {
            _showDialog(
              context,
              title: 'Error',
              message: state.message ?? 'Something went wrong.',
              icon: Icons.error_outline,
              color: Colors.red,
            );
          } else if (state.status == SignupStatus.success) {
            _showDialog(
              context,
              title: 'Success',
              message: 'Signup successful!',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onOk: () => _navigateToLogin(context),
            );
          } else if (state.status == SignupStatus.imageError) {
            _showSnackbar(
                context: context,
                message: state.message ?? 'Error selecting image.',
                success: false);
          } else if (state.status == SignupStatus.imageSuccess) {
            _showSnackbar(
                context: context,
                message: 'Image uploaded successfully',
                success: true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<SignupCubit>();
          final isLoading = state.status == SignupStatus.loading;
          final isImageLoading = state.status == SignupStatus.imageLoading;
          final File? profileImage = state.profileImage;

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              systemOverlayStyle:
                  Theme.of(context).brightness == Brightness.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark,
              actions: [
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, themeState) {
                    final isDark = themeState.themeMode == ThemeMode.dark;
                    return IconButton(
                      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                      onPressed: () {
                        context.read<ThemeCubit>().changeTheme(
                              isDark ? ThemeMode.light : ThemeMode.dark,
                            );
                      },
                    );
                  },
                ),
              ],
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: cubit.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CustomText(
                        'Create your Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      /// Profile image
                      UserImage(
                        cubit: cubit,
                        isImageLoading: isImageLoading,
                        profileImage: profileImage,
                      ),

                      const SizedBox(height: 30),

                      /// User info
                      UserInfo(
                        cubit: cubit,
                        state: state,
                      ),

                      const SizedBox(height: 30),

                      /// Sign Up Button
                      actionButton(cubit, profileImage, isLoading, context),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Column actionButton(
    SignupCubit cubit,
    File? profileImage,
    bool isLoading,
    BuildContext context,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (!(cubit.formKey.currentState?.validate() ?? false)) {
                        return;
                      }

                      cubit.signUpWithEmailAndPassword(
                        email: cubit.emailController.text.trim(),
                        password: cubit.passwordController.text.trim(),
                        displayName: cubit.displayNameController.text.trim(),
                        profileImage: profileImage,
                      );
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign Up'),
            ),
          ),
        ),
        const SizedBox(height: 15),

        /// Login Navigation
        TextButton(
          onPressed: () {
            _navigateToLogin(context);
          },
          child: const Text('Already have an account? Log In'),
        ),
      ],
    );
  }
}
