import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_text_field.dart';
import '../../viewmodel/signup_cubit.dart';
import '../../viewmodel/signup_state.dart';

class UserInfo extends StatelessWidget {
  const UserInfo({
    super.key,
    required this.cubit,
    required this.state,
  });

  final SignupCubit cubit;
  final SignupState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// Form fields
        CustomTextField(
          controller: cubit.displayNameController,
          labelText: 'Display Name (Optional)',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value != null && value.length > 50) {
              return 'Display name must be less than 50 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: cubit.emailController,
          labelText: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: cubit.passwordController,
          labelText: 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: !state.isPasswordVisible,
          suffixIcon: state.isPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixIconTap: () => cubit.togglePasswordVisibility(),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: cubit.confirmPasswordController,
          labelText: 'Confirm Password',
          prefixIcon: Icons.lock_outline,
          suffixIcon: state.isConfirmPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixIconTap: () => cubit.toggleConfirmPasswordVisibility(),
          obscureText: !state.isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != cubit.passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}
