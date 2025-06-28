import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  MenuCubit() : super(const MenuState(status: MenuStatus.initial));

  Future<void> signOut(BuildContext context) async {
    emit(state.copyWith(status: MenuStatus.logoutLoading));
    try {
      await Future.delayed(const Duration(milliseconds: 3000));
      await supabase.Supabase.instance.client.auth.signOut();
      emit(state.copyWith(
          status: MenuStatus.logoutSuccess, data: 'LogoutSuccess'));
    } catch (e) {
      emit(state.copyWith(
          status: MenuStatus.logoutError, message: e.toString()));
      debugPrint("Error during logout: ${e.toString()}");
    }
  }
}
