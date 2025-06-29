enum ProfileStatus {
  initial,
  profileloading,
  profilesuccess,
  profileerror,
}

class ProfileState {
  final ProfileStatus status;
  final String? message;
  final dynamic data;

  final bool isPasswordVisible;

  const ProfileState({
    required this.status,
    this.message,
    this.data,
    this.isPasswordVisible = false,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? message,
    dynamic data,
    bool? isPasswordVisible,
  }) {
    return ProfileState(
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
