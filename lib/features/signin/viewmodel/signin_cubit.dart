import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'signin_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SigninCubit extends Cubit<SigninState> {
  SigninCubit() : super(SigninState(status: SigninStatus.initial));

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  // Form State
  final formKey = GlobalKey<FormState>();
  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      emit(state.copyWith(status: SigninStatus.signinloading));

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        emit(state.copyWith(
            status: SigninStatus.signinerror,
            message: 'Failed to signin user account'));
        return;
      }

      emit(state.copyWith(
          status: SigninStatus.signinsuccess, data: response.user));
    } on supabase.AuthException catch (e) {
      _handleAuthException(e, 'sign in');
    } catch (e) {
      emit(state.copyWith(
          status: SigninStatus.signinerror,
          message: 'An unexpected error occurred. $e'));
    }
  }

  void _handleAuthException(supabase.AuthException e, String operation) {
    final msg = e.message;

    if (msg.contains('Invalid login credentials')) {
      emit(state.copyWith(
        status: SigninStatus.signinerror,
        message: 'Wrong email or password.',
      ));
    } else if (msg.contains('Email not confirmed')) {
      emit(state.copyWith(
        status: SigninStatus.signinerror,
        message: 'Please confirm your email address.',
      ));
    } else if (msg.contains('User not found')) {
      emit(state.copyWith(
        status: SigninStatus.signinerror,
        message: 'No user found with this email.',
      ));
    } else if (msg.contains('Too many requests')) {
      emit(state.copyWith(
        status: SigninStatus.signinerror,
        message: 'Too many attempts. Please wait a moment and try again.',
      ));
    } else {
      emit(state.copyWith(status: SigninStatus.signinerror, message: msg));
    }
  }

  Future<void> signOut() async {
    try {
      emit(state.copyWith(status: SigninStatus.signoutloading));
      await _supabase.auth.signOut();
      emit(state.copyWith(status: SigninStatus.signoutsuccess));
    } catch (e) {
      emit(state.copyWith(
        status: SigninStatus.signouterror,
        message: 'An unexpected error occurred. $e',
      ));
    }
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }
}
