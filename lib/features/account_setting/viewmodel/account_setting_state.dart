import 'dart:io';

/// Enum to represent the various states of account settings operations.
enum AccountSettingStatus {
  initial,
  loading,
  success,
  error,
  imageLoading,
  imageSuccess,
  imageError,
}

/// State class for managing account setting screen state.
class AccountSettingState {
  final AccountSettingStatus status;
  final String? message;
  final dynamic data;
  final File? profileImage;
  final bool isOldPasswordVisible;
  final bool isNewConfirmPasswordVisible;

  const AccountSettingState({
    required this.status,
    this.message,
    this.data,
    this.profileImage,
    this.isOldPasswordVisible = false,
    this.isNewConfirmPasswordVisible = false,
  });

  /// Creates a new state with updated values
  AccountSettingState copyWith({
    AccountSettingStatus? status,
    String? message,
    dynamic data,
    File? profileImage,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
  }) {
    return AccountSettingState(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
      profileImage: profileImage ?? this.profileImage,
      isOldPasswordVisible: isPasswordVisible ?? isOldPasswordVisible,
      isNewConfirmPasswordVisible:
          isConfirmPasswordVisible ?? isNewConfirmPasswordVisible,
    );
  }

  @override
  String toString() {
    return status.toString();
  }
}
