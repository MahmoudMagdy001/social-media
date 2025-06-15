import 'package:facebook_clone/models/friends_model.dart';
import 'package:facebook_clone/utils/execute_with_retry.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class FriendService {
  final user = supabase.Supabase.instance.client.auth.currentUser;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  static const String _usersTable = 'users';

  // New constants for friend requests
  static const String _friendRequestsTable = 'friend_requests';
  static const String _friendsTable = 'friends';

  final supabase.SupabaseClient _supabase;

  FriendService({supabase.SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase.Supabase.instance.client;

  /// Get all pending friend requests for a user
  Future<List<FriendRequestModel>> getPendingRequests(String userId) async {
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    final response = await executeWithRetry(() async {
      return await _supabase
          .from(_friendRequestsTable)
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);

    return (response as List)
        .map((item) => FriendRequestModel.fromMap(item))
        .toList();
  }

  /// Get all sent friend requests that are still pending
  Future<List<FriendRequestModel>> getSentRequests(String userId) async {
    final response = await _supabase
        .from(_friendRequestsTable)
        .select()
        .eq('sender_id', userId)
        .eq('status', 'pending');

    return (response as List)
        .map((r) => FriendRequestModel.fromMap(r))
        .toList();
  }

  /// Check if two users are friends
  Future<bool> areFriends({
    required String userId1,
    required String userId2,
  }) async {
    if (userId1.isEmpty || userId2.isEmpty) {
      throw ArgumentError('User IDs cannot be empty');
    }

    final response = await executeWithRetry(() async {
      return await _supabase
          .from(_friendsTable)
          .select()
          .or('user1_id.eq.$userId1,user2_id.eq.$userId1')
          .or('user1_id.eq.$userId2,user2_id.eq.$userId2')
          .maybeSingle();
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);

    return response != null;
  }

  Future<List<Map<String, dynamic>>> getAllUsersExceptCurrent() async {
    final response = await _supabase
        .from(_usersTable)
        .select()
        .neq('id', user!.id)
        .order('display_name', ascending: true);

    return response;
  }

  Future<List<FriendRequestModel>> getFriendRequests(String userId) async {
    final response = await _supabase
        .from(_friendRequestsTable)
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .eq('status', 'pending');

    return (response as List)
        .map((r) => FriendRequestModel.fromMap(r))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final response = await _supabase
        .from(_friendsTable)
        .select('user1_id, user2_id')
        .or('user1_id.eq.$userId,user2_id.eq.$userId');

    // Get friend details
    final friendIds = response
        .map((f) => f['user1_id'] == userId ? f['user2_id'] : f['user1_id'])
        .toList();

    if (friendIds.isEmpty) return [];

    final friends =
        await _supabase.from(_usersTable).select().inFilter('id', friendIds);

    return friends;
  }

  Future<void> deleteFriend({
    required String userId,
    required String friendId,
  }) async {
    if (userId.isEmpty || friendId.isEmpty) {
      throw ArgumentError('User IDs cannot be empty');
    }

    // Delete the friendship record where userId is user1_id and friendId is user2_id
    await executeWithRetry(() async {
      return await _supabase
          .from(_friendsTable)
          .delete()
          .eq('user1_id', userId)
          .eq('user2_id', friendId);
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);

    // Delete the friendship record where friendId is user1_id and userId is user2_id
    await executeWithRetry(() async {
      return await _supabase
          .from(_friendsTable)
          .delete()
          .eq('user1_id', friendId)
          .eq('user2_id', userId);
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
  }

  Future<void> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final sender = await _supabase
        .from(_usersTable)
        .select('display_name, profile_image')
        .eq('id', senderId)
        .single();

    final receiver = await _supabase
        .from(_usersTable)
        .select('display_name, profile_image')
        .eq('id', receiverId)
        .single();

    await _supabase.from(_friendRequestsTable).insert({
      'sender_id': senderId,
      'sender_name': sender['display_name'],
      'sender_image': sender['profile_image'],
      'receiver_id': receiverId,
      'receiver_name': receiver['display_name'],
      'receiver_image': receiver['profile_image'],
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> cancelFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    await _supabase
        .from(_friendRequestsTable)
        .delete()
        .eq('sender_id', senderId)
        .eq('receiver_id', receiverId);
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String receiverId,
  }) async {
    // Get the original friend request details
    final request = await _supabase
        .from(_friendRequestsTable)
        .select(
            'sender_id, sender_name, sender_image, receiver_name, receiver_image')
        .eq('id', requestId)
        .single();

    final senderId = request['sender_id'];
    String? senderName = request['sender_name'];
    String? receiverName = request['receiver_name'];
    String? senderImage = request['sender_image'];
    String? receiverImage = request['receiver_image'];

    // Fallback if any detail is null
    if (senderName == null ||
        receiverName == null ||
        senderImage == null ||
        receiverImage == null) {
      final senderData = await _supabase
          .from(_usersTable)
          .select('display_name, profile_image')
          .eq('id', senderId)
          .single();

      final receiverData = await _supabase
          .from(_usersTable)
          .select('display_name, profile_image')
          .eq('id', receiverId)
          .single();

      senderName ??= senderData['display_name'];
      senderImage ??= senderData['profile_image'];
      receiverName ??= receiverData['display_name'];
      receiverImage ??= receiverData['profile_image'];

      debugPrint(
          'Warning: Some friend request fields were null. Filled from users table.');
    }

    // Create friendship records in the _friendsTable
    await _supabase.from(_friendsTable).insert([
      {
        'user1_id': senderId,
        'user1_name': senderName,
        'user1_image': senderImage,
        'user2_id': receiverId,
        'user2_name': receiverName,
        'user2_image': receiverImage,
      },
      {
        'user1_id': receiverId,
        'user1_name': receiverName,
        'user1_image': receiverImage,
        'user2_id': senderId,
        'user2_name': senderName,
        'user2_image': senderImage,
      }
    ]);

    // Delete the friend request
    await _supabase.from(_friendRequestsTable).delete().eq('id', requestId);
  }

  Future<void> rejectFriendRequest({
    required String requestId,
    required String receiverId,
  }) async {
    await _supabase.from(_friendRequestsTable).delete().eq('id', requestId);
  }
}
