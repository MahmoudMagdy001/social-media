import 'package:facebook_clone/screens/menu/profile_header.dart';
import 'package:facebook_clone/screens/posts/post_section/posts_list.dart';
import 'package:facebook_clone/services/friend_services/friend_service.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/custom_icon_button.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:facebook_clone/widgets/shimmer.dart';
import 'package:flutter/material.dart';

import '../../models/post_data_model.dart';

class UserProfile extends StatefulWidget {
  final String displayName;
  final String imageUrl;
  final String userId;
  final String currentUserId;

  const UserProfile({
    super.key,
    required this.displayName,
    required this.imageUrl,
    required this.userId,
    required this.currentUserId,
  });

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();

  late Future<List<PostDataModel>> _postsFuture;
  late Future<List<Map<String, dynamic>>> _friendsFuture;
  late bool isOwner;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _postsFuture = _postService.getPostsForCurrentUser(widget.userId);
    _friendsFuture = _friendService.getFriends(widget.userId);
    isOwner = widget.userId == widget.currentUserId;
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadUserData();
    });
  }

  void _handlePostDeleted() {
    setState(() {
      _postsFuture = _postService.getPostsForCurrentUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            userId: widget.userId,
            currentUserId: widget.currentUserId,
            isOwner: isOwner,
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
          userId: widget.userId,
          currentUserId: widget.currentUserId,
          isOwner: isOwner,
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
  final String userId;
  final String currentUserId;
  final bool isOwner;

  const _PostsListView({
    required this.posts,
    required this.onRefresh,
    required this.profileImage,
    required this.displayName,
    required this.friendsList,
    required this.friendService,
    required this.postService,
    this.onPostDeleted,
    this.friendsError,
    required this.userId,
    required this.currentUserId,
    required this.isOwner,
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
                  isOwner: isOwner,
                ),
                const Divider(),
              ],
            ),
          ),
          if (posts.isEmpty && friendsError == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article_outlined,
                        size: 60, color: Colors.grey[500]),
                    const SizedBox(height: 16),
                    Text(
                      'You have no Posts yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share the post with others!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            PostsList(
              posts: posts,
              onRefresh: onRefresh,
              postService: postService,
              userId: userId,
              currentUserId: currentUserId,
            )
        ],
      ),
    );
  }
}
