import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../model/layout_model.dart';
import 'layout_state.dart';

class LayoutCubit extends Cubit<LayoutState> {
  LayoutCubit() : super(LayoutState(status: LayoutStatus.initial));

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  static const String _usersTable = 'users';

  Future<void> getUser() async {
    emit(state.copyWith(status: LayoutStatus.userLoading));
    try {
      final userData = await _supabase
          .from(_usersTable)
          .select()
          .eq('id', _supabase.auth.currentUser!.id)
          .single();

      final UserModel user = UserModel.fromJson(userData);
      emit(state.copyWith(
        status: LayoutStatus.userSuccess,
        data: user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LayoutStatus.userError,
        message: 'An unexpected error occurred. $e',
      ));
    }
  }
}
