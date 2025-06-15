import 'package:facebook_clone/screens/friends/friend_list.dart';
import 'package:facebook_clone/services/friend_services/friend_service.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/custom_icon_button.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../models/post_data_model.dart';
import '../posts/posts_section/post_item.dart';
import '../posts/posts_section/post_shimmer_item.dart';

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
  final supabase.User? _currentUser = // Renamed for clarity
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
      _loadUserData(); // Reload both posts and friends
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
          return const _ShimmerList(); // Shows shimmer while posts are loading
        }

        if (postsSnapshot.hasError) {
          return Center(
            child: CustomText('Error loading posts: ${postsSnapshot.error}'),
          );
        }

        if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
          // Still need to load friends to show profile header even if no posts
          return _buildFriendsLoaderAndProfileView(
            posts: const [], // Pass empty list if no posts
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

  // New widget to handle loading friends and then displaying the full profile view
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
          return const _ShimmerList(); // Or a more targeted shimmer
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
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String profileImage;
  final String displayName;
  final List<Map<String, dynamic>> friendsList;
  final FriendService friendService;
  final String? friendsError; // Optional error message for friends

  const _ProfileHeader({
    required this.profileImage,
    required this.displayName,
    required this.friendsList,
    required this.friendService,
    this.friendsError,
  });

  @override
  Widget build(BuildContext context) {
    final friendsCount = friendsList.length;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: NetworkImage(profileImage),
            backgroundColor: Colors.grey[300], // Fallback color
          ),
          const SizedBox(height: 10),
          CustomText(
            displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Divider(),
          Row(
            children: [
              CustomText(
                friendsCount.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              CustomText(friendsCount == 1 ? 'Friend' : 'Friends'),
              const Spacer(),
              if (friendsError ==
                  null) // Only show "show all friends" if no error
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return FriendsList(
                            friendsList: friendsList,
                            friendService: friendService,
                          );
                        },
                      ),
                    );
                  },
                  child: CustomText(
                    'show all friends',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
            ],
          ),
          if (friendsError != null) ...[
            const SizedBox(height: 5),
            CustomText(friendsError!,
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          if (friendsList.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: friendsList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 15),
                itemBuilder: (context, index) {
                  final friend = friendsList[index];
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            NetworkImage(friend['profile_image'] ?? ''),
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 60,
                        child: Text(
                          friend['display_name'] ?? 'N/A',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
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
  final String?
      friendsError; // Optional error message for friends display in header

  const _PostsListView({
    required this.posts,
    this.onPostDeleted,
    required this.onRefresh,
    required this.profileImage,
    required this.displayName,
    required this.friendsList,
    required this.friendService,
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
            // Using SliverToBoxAdapter for a single complex item
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(
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
          if (posts.isEmpty &&
              friendsError ==
                  null) // Check friendsError to avoid double message
            SliverFillRemaining(
              // Use SliverFillRemaining to show message if no posts
              child: Center(
                  child:
                      CustomText('No posts available. Pull down to refresh.')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = posts[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PostItem(
                        postData: post,
                        onPostDeleted: onPostDeleted,
                      ),
                      if (index < posts.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Divider(),
                        ),
                    ],
                  );
                },
                childCount: posts.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        // Prevent scrolling of shimmer
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer for Profile Section
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 20,
                    width: 150,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10), // For divider space
                  // Shimmer for friends count area
                  Row(
                    children: [
                      Container(height: 16, width: 30, color: Colors.white),
                      const SizedBox(width: 5),
                      Container(height: 16, width: 60, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Shimmer for friends list (simplified)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3, // Show a few shimmer friend items
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: Column(
                          children: [
                            const CircleAvatar(
                                radius: 28, backgroundColor: Colors.white),
                            const SizedBox(height: 5),
                            Container(
                                width: 60, height: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const Divider(), // Match the structure
            // Shimmer for Post Items
            ListView.builder(
              // Use ListView.builder for shimmer posts
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Number of shimmer post items
              itemBuilder: (_, __) =>
                  const PostShimmerItem(), // Assuming PostShimmerItem handles its own internal dividers or spacing
            ),
          ],
        ),
      ),
    );
  }
}
