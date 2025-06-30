part of 'friends_cubit.dart';

abstract class FriendsState {}

class FriendsInitial extends FriendsState {}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final List<Map<String, dynamic>> users;
  final Map<String, FriendRequestStatus> requestStatus;
  FriendsLoaded(this.users, this.requestStatus);
}

class FriendsError extends FriendsState {
  final String message;
  FriendsError(this.message);
}
