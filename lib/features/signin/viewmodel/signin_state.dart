enum SigninStatus {
  initial,
  signinloading,
  signinsuccess,
  signinerror,
  signoutloading,
  signoutsuccess,
  signouterror,
}

class SigninState {
  final SigninStatus status;
  final String? message;
  final dynamic data;

  final bool isPasswordVisible;

  const SigninState({
    required this.status,
    this.message,
    this.data,
    this.isPasswordVisible = false,
  });

  SigninState copyWith({
    SigninStatus? status,
    String? message,
    dynamic data,
    bool? isPasswordVisible,
  }) {
    return SigninState(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }

  @override
  String toString() {
    return status.toString();
  }
}
