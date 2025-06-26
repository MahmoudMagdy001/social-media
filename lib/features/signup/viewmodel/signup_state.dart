import 'dart:io';

enum SignupStatus {
  initial,
  loading,
  success,
  error,
  imageLoading,
  imageSuccess,
  imageError,
}

class SignupState {
  final SignupStatus status;
  final String? message;
  final dynamic data;
  final File? profileImage;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;

  const SignupState({
    required this.status,
    this.message,
    this.data,
    this.profileImage,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
  });

  SignupState copyWith({
    SignupStatus? status,
    String? message,
    dynamic data,
    File? profileImage,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
  }) {
    return SignupState(
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
        profileImage: profileImage ?? this.profileImage,
        isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
        isConfirmPasswordVisible:
            isConfirmPasswordVisible ?? this.isConfirmPasswordVisible);
  }

  @override
  String toString() {
    return status.toString();
  }
}
