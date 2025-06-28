enum MenuStatus {
  initial,
  logoutLoading,
  logoutSuccess,
  logoutError,
}

class MenuState {
  final MenuStatus status;
  final String? message;
  final dynamic data;

  const MenuState({
    required this.status,
    this.message,
    this.data,
  });

  MenuState copyWith({
    MenuStatus? status,
    String? message,
    dynamic data,
  }) {
    return MenuState(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return status.toString();
  }
}
