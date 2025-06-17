import 'package:facebook_clone/screens/menu/profile_header.dart';
import 'package:facebook_clone/screens/posts/posts_section/posts_list.dart';
import 'package:facebook_clone/services/friend_services/friend_service.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/custom_icon_button.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:facebook_clone/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../models/post_data_model.dart';

class UserProfile extends StatefulWidget {
  final String displayName;
  final String imageUrl;
  final String email;

  const UserProfile({
    super.key,
    required this.displayName,
    required this.imageUrl,
    required this.email,
  });

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final supabase.User? _currentUser =
      supabase.Supabase.instance.client.auth.currentUser;

  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();

  late Future<List<PostDataModel>> _postsFuture;
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _loadUserData();
    }
  }

  void _loadUserData() {
    if (_currentUser == null) return;
    _postsFuture = _postService.getPostsForCurrentUser(_currentUser!.id);
    _friendsFuture = _friendService.getFriends(_currentUser!.id);
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadUserData();
    });
  }

  void _handlePostDeleted() {
    setState(() {
      if (_currentUser != null) {
        _postsFuture = _postService.getPostsForCurrentUser(_currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CustomText('User not logged in. Please log in to continue.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CustomIconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              iconData: Icons.arrow_back_ios,
            ),
            const Text('Profile'),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    return FutureBuilder<List<PostDataModel>>(
      future: _postsFuture,
      builder: (context, postsSnapshot) {
        if (postsSnapshot.connectionState == ConnectionState.waiting) {
          return const ProfileShimmer();
        }

        if (postsSnapshot.hasError) {
          return Center(
            child: CustomText('Error loading posts: ${postsSnapshot.error}'),
          );
        }

        if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
          return _buildFriendsLoaderAndProfileView(
            posts: const [],
            onPostDeleted: _handlePostDeleted,
            onRefresh: _refreshData,
          );
        }

        final posts = postsSnapshot.data!;
        return _buildFriendsLoaderAndProfileView(
          posts: posts,
          onPostDeleted: _handlePostDeleted,
          onRefresh: _refreshData,
        );
      },
    );
  }

  Widget _buildFriendsLoaderAndProfileView({
    required List<PostDataModel> posts,
    required VoidCallback onPostDeleted,
    required Future<void> Function() onRefresh,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _friendsFuture,
      builder: (context, friendsSnapshot) {
        if (friendsSnapshot.connectionState == ConnectionState.waiting &&
            posts.isEmpty) {
          return const ProfileShimmer();
        }

        if (friendsSnapshot.hasError) {
          return _PostsListView(
            posts: posts,
            onPostDeleted: onPostDeleted,
            onRefresh: onRefresh,
            profileImage: widget.imageUrl,
            displayName: widget.displayName,
            friendsList: const [],
            friendService: _friendService,
            friendsError: 'Could not load friends: ${friendsSnapshot.error}',
            postService: _postService,
            user: _currentUser!,
          );
        }

        final friends = friendsSnapshot.data ?? [];

        return _PostsListView(
          posts: posts,
          onPostDeleted: onPostDeleted,
          onRefresh: onRefresh,
          profileImage: widget.imageUrl,
          displayName: widget.displayName,
          friendsList: friends,
          friendService: _friendService,
          postService: _postService,
          user: _currentUser!,
        );
      },
    );
  }
}

class _PostsListView extends StatelessWidget {
  final List<PostDataModel> posts;
  final VoidCallback? onPostDeleted;
  final Future<void> Function() onRefresh;
  final String profileImage;
  final String displayName;
  final List<Map<String, dynamic>> friendsList;
  final FriendService friendService;
  final String? friendsError;
  final PostService postService;
  final supabase.User user;

  const _PostsListView({
    required this.posts,
    required this.onRefresh,
    required this.profileImage,
    required this.displayName,
    required this.friendsList,
    required this.friendService,
    required this.postService,
    required this.user,
    this.onPostDeleted,
    this.friendsError,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(
                  profileImage: profileImage,
                  displayName: displayName,
                  friendsList: friendsList,
                  friendService: friendService,
                  friendsError: friendsError,
                ),
                const Divider(),
              ],
            ),
          ),
          if (posts.isEmpty && friendsError == null)
            SliverFillRemaining(
              child: Center(
                child: CustomText(
                  'No posts available. Pull down to refresh.',
                ),
              ),
            )
          else
            PostsList(
              posts: posts,
              onRefresh: onRefresh,
              postService: postService,
              user: user,
            )
        ],
      ),
    );
  }
}
