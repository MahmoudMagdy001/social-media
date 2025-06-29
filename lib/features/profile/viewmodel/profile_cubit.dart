import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/post_data_model.dart';
import 'profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState(status: ProfileStatus.initial));
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  static const String _postsTable = 'posts';
  static const String _friendsTable = 'friends';
  static const String _usersTable = 'users';
  final PostService postService = PostService();

  Future<void> loadUserProfile(String userId) async {
    emit(state.copyWith(status: ProfileStatus.profileloading));

    try {
      final posts = await getPostsForCurrentUser(userId);
      final friends = await getFriends(userId);

      emit(state.copyWith(
        status: ProfileStatus.profilesuccess,
        data: {
          'posts': posts,
          'friends': friends,
        },
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.profileerror,
        message: 'Failed to load profile data',
      ));
    }
  }

  Future<List<PostDataModel>> getPostsForCurrentUser(
      String currentUserId) async {
    try {
      final response = await _supabase
          .from(_postsTable)
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      // Defensive cast & mapping
      final data = response as List<dynamic>;

      return data.map<PostDataModel>((item) {
        final documentId = item['id'];
        return PostDataModel.fromMap(item, documentId);
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting posts: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    // Step 1: Get all friend rows where userId is user1
    final response = await _supabase
        .from(_friendsTable)
        .select(
            'user2_id') // only need user2_id since user1 is the current user
        .eq('user1_id', userId);

    // Step 2: Extract the list of friend user IDs
    final friendIds = response.map((f) => f['user2_id'] as String).toList();

    if (friendIds.isEmpty) return [];

    // Step 3: Fetch user details for all friend user IDs
    final friends =
        await _supabase.from(_usersTable).select().inFilter('id', friendIds);

    return friends;
  }
}
