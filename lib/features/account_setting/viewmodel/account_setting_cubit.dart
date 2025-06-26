import 'package:flutter_bloc/flutter_bloc.dart';
import 'account_setting_state.dart';

class AccountSettingCubit extends Cubit<AccountSettingState> {
  AccountSettingCubit() : super(AccountSettingInitial());

  void example() {
    emit(AccountSettingLoading());
    emit(AccountSettingSuccess());
  }
}
