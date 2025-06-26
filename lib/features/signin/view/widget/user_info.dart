import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_text_field.dart';
import '../../viewmodel/signin_cubit.dart';
import '../../viewmodel/signin_state.dart';

class UserInfo extends StatelessWidget {
  const UserInfo({
    super.key,
    required this.cubit,
    required this.state,
  });

  final SigninCubit cubit;
  final SigninState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          controller: cubit.emailController,
          labelText: 'Email',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
          controller: cubit.passwordController,
          labelText: 'Password',
          obscureText: !state.isPasswordVisible,
          prefixIcon: Icons.lock_outline,
          keyboardType: TextInputType.visiblePassword,
          suffixIcon: !state.isPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixIconTap: () => cubit.togglePasswordVisibility(),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {},
        ),
      ],
    );
  }
}
