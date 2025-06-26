import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'signin_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SigninCubit extends Cubit<SigninState> {
  SigninCubit() : super(SigninState(status: SigninStatus.initial));

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  static const String _usersTable = 'users';

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
      final user = response.user;

      if (user == null) {
        emit(state.copyWith(
            status: SigninStatus.signinerror,
            message: 'Failed to signin user account'));
        return;
      }

      final userData = await _supabase
          .from(_usersTable)
          .select()
          .eq('id', response.user!.id)
          .single();

      emit(state.copyWith(status: SigninStatus.signinsuccess, data: userData));
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

    if (msg.contains('Email already registered')) {
      emit(state.copyWith(
        status: SigninStatus.signinerror,
        message: 'This email is already registered.',
      ));
    } else if (msg.contains('Invalid email')) {
      emit(state.copyWith(
        status: SigninStatus.signinerror,
        message: 'The email address is invalid.',
      ));
    } else if (msg.contains('Invalid login credentials')) {
      emit(state.copyWith(
        status: SigninStatus.signinerror,
        message: 'Wrong email or password.',
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
