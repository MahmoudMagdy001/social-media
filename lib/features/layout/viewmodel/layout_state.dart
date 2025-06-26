import 'package:facebook_clone/features/layout/model/layout_model.dart';

enum LayoutStatus {
  initial,
  userLoading,
  userSuccess,
  userError,
}

class LayoutState {
  final LayoutStatus status;
  final String? message;
  final UserModel? data;

  const LayoutState({
    required this.status,
    this.message,
    this.data,
  });

  LayoutState copyWith({
    LayoutStatus? status,
    String? message,
    UserModel? data,
  }) {
    return LayoutState(
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
