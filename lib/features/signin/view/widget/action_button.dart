import 'package:flutter/material.dart';

import '../../../signup/view/signup_view.dart';
import '../../viewmodel/signin_cubit.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.cubit,
    required this.isLoading,
  });

  final SigninCubit cubit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (!(cubit.formKey.currentState?.validate() ??
                            false)) {
                          return;
                        }
                        cubit.signInWithEmailAndPassword(
                            email: cubit.emailController.text.trim(),
                            password: cubit.passwordController.text.trim(),
                            context: context);
                      },
                child: isLoading
                    ? Center(
                        child: SizedBox(
                        width: 18,
                        height: 18,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ))
                    : const Text('Login')),
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) {
                  return SignupView();
                },
              ),
            );
          },
          child: const Text('Don\'t have an account? Sign Up'),
        ),
      ],
    );
  }
}
