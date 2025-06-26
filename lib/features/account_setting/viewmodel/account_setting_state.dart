abstract class AccountSettingState {}

class AccountSettingInitial extends AccountSettingState {}

class AccountSettingLoading extends AccountSettingState {}

class AccountSettingSuccess extends AccountSettingState {}

class AccountSettingError extends AccountSettingState {
  final String message;
  AccountSettingError(this.message);
}
