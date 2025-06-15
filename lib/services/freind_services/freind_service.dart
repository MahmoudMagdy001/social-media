import 'package:facebook_clone/models/friends_model.dart';
import 'package:facebook_clone/utils/execute_with_retry.dart';
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
        .from('friend_requests')
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
        .from('friends')
        .select('user1_id, user2_id')
        .or('user1_id.eq.$userId,user2_id.eq.$userId');

    // Get friend details
    final friendIds = response
        .map((f) => f['user1_id'] == userId ? f['user2_id'] : f['user1_id'])
        .toList();

    if (friendIds.isEmpty) return [];

    final friends =
        await _supabase.from('users').select().inFilter('id', friendIds);

    return friends;
  }

  Future<void> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final sender = await _supabase
        .from('users')
        .select('display_name, profile_image')
        .eq('id', senderId)
        .single();

    final receiver = await _supabase
        .from('users')
        .select('display_name, profile_image')
        .eq('id', receiverId)
        .single();

    await _supabase.from('friend_requests').insert({
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
        .from('friend_requests')
        .delete()
        .eq('sender_id', senderId)
        .eq('receiver_id', receiverId);
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String receiverId,
  }) async {
    // Update request status
    await _supabase
        .from('friend_requests')
        .update({'status': 'accepted'}).eq('id', requestId);

    // Create friendship records
    final request = await _supabase
        .from('friend_requests')
        .select()
        .eq('id', requestId)
        .single();

    await _supabase.from('friends').insert([
      {'user1_id': request['sender_id'], 'user2_id': receiverId},
      {'user1_id': receiverId, 'user2_id': request['sender_id']},
    ]);
  }

  Future<void> rejectFriendRequest({
    required String requestId,
    required String receiverId,
  }) async {
    await _supabase
        .from('friend_requests')
        .update({'status': 'rejected'}).eq('id', requestId);
  }
}
