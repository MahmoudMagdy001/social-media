import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/core/services/friend_services/friend_service.dart';

part 'friends_state.dart';

enum FriendRequestStatus {
  none,
  sent,
  received,
  friends,
}

class FriendsCubit extends Cubit<FriendsState> {
  final FriendService friendService;
  final String userId;

  FriendsCubit({required this.friendService, required this.userId})
      : super(FriendsInitial());

  Future<void> fetchFriendsData() async {
    emit(FriendsLoading());
    try {
      final users = await friendService.getAllUsersExceptCurrent();
      final requests = await friendService.getFriendRequests(userId);
      final statusMap = <String, FriendRequestStatus>{};
      for (var request in requests) {
        if (request.senderId == userId) {
          statusMap[request.receiverId] = FriendRequestStatus.sent;
        } else if (request.receiverId == userId) {
          statusMap[request.senderId] = FriendRequestStatus.received;
        }
      }
      final friends = await friendService.getFriends(userId);
      for (var friend in friends) {
        final friendId = friend['id'];
        statusMap[friendId] = FriendRequestStatus.friends;
      }
      emit(FriendsLoaded(users, statusMap));
    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }

  // إرسال طلب صداقة
  Future<void> sendRequest(String receiverId) async {
    try {
      await friendService.sendFriendRequest(
          senderId: userId, receiverId: receiverId);
      await fetchFriendsData();
    } catch (e) {
      emit(FriendsError('Failed to send request: $e'));
    }
  }

  // إلغاء طلب صداقة مرسل
  Future<void> cancelRequest(String receiverId) async {
    try {
      await friendService.cancelFriendRequest(
          senderId: userId, receiverId: receiverId);
      await fetchFriendsData();
    } catch (e) {
      emit(FriendsError('Failed to cancel request: $e'));
    }
  }

  // قبول طلب صداقة مستلم
  Future<void> acceptRequest(String senderId) async {
    try {
      // ابحث عن الطلب المناسب
      final requests = await friendService.getFriendRequests(userId);
      final req = requests.firstWhere(
          (r) => r.senderId == senderId && r.receiverId == userId,
          orElse: () => throw Exception('Request not found'));
      await friendService.acceptFriendRequest(
          requestId: req.id, receiverId: userId);
      await fetchFriendsData();
    } catch (e) {
      emit(FriendsError('Failed to accept request: $e'));
    }
  }

  // رفض طلب صداقة مستلم
  Future<void> rejectRequest(String senderId) async {
    try {
      final requests = await friendService.getFriendRequests(userId);
      final req = requests.firstWhere(
          (r) => r.senderId == senderId && r.receiverId == userId,
          orElse: () => throw Exception('Request not found'));
      await friendService.rejectFriendRequest(
          requestId: req.id, receiverId: userId);
      await fetchFriendsData();
    } catch (e) {
      emit(FriendsError('Failed to reject request: $e'));
    }
  }
}
