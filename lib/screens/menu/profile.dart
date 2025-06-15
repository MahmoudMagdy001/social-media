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
  final supabase.User? currentUser =
      supabase.Supabase.instance.client.auth.currentUser;

  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();

  late Future<List<PostDataModel>> _postsFuture;
  late Future<List<Map<String, dynamic>>> friendsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.getPostsForCurrentUser(currentUser!.id);
    friendsFuture = _friendService.getFriends(currentUser!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CustomText('User not logged in.'),
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
            const Text(
              'Profile',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildPostsAndFriendsList(),
      ),
    );
  }

  Widget _buildPostsAndFriendsList() {
    return FutureBuilder<List<PostDataModel>>(
      future: _postsFuture,
      builder: (context, postsSnapshot) {
        if (postsSnapshot.connectionState == ConnectionState.waiting) {
          return const _ShimmerList();
        }

        if (!postsSnapshot.hasData) {
          return const Center(
            child: CustomText('No posts available or failed to load.'),
          );
        }

        final posts = postsSnapshot.data!;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: friendsFuture,
          builder: (context, friendsSnapshot) {
            final friends = friendsSnapshot.data ?? [];
            final friendsCount = friends.length;

            return _PostsListView(
              posts: posts,
              onPostDeleted: () {
                setState(() {
                  _postsFuture =
                      _postService.getPostsForCurrentUser(currentUser!.id);
                });
              },
              onRefresh: () async {
                setState(() {
                  _postsFuture =
                      _postService.getPostsForCurrentUser(currentUser!.id);
                  friendsFuture = _friendService.getFriends(currentUser!.id);
                });
              },
              profileImage: widget.imageUrl,
              displayName: widget.displayName,
              friendsCount: friendsCount,
              friendsList: friends,
            );
          },
        );
      },
    );
  }
}

class _PostsListView extends StatelessWidget {
  final List<PostDataModel> posts;
  final void Function()? onPostDeleted;
  final Future<void> Function() onRefresh;
  final String profileImage;
  final String displayName;
  final num friendsCount;
  final List<Map<String, dynamic>> friendsList;

  const _PostsListView({
    required this.posts,
    this.onPostDeleted,
    required this.onRefresh,
    required this.profileImage,
    required this.displayName,
    required this.friendsCount,
    required this.friendsList,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: 1,
              (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundImage: NetworkImage(profileImage),
                          ),
                          const SizedBox(height: 10),
                          CustomText(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              CustomText(
                                friendsCount.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 5),
                              CustomText(
                                  friendsCount == 1 ? 'Friend' : 'Friends'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (friendsList.isNotEmpty)
                            SizedBox(
                              height: 135,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: friendsList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 15),
                                itemBuilder: (context, index) {
                                  final friend = friendsList[index];
                                  return Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundImage: NetworkImage(
                                            friend['profile_image'] ?? ''),
                                        backgroundColor: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 5),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          friend['display_name'] ?? '',
                                          textAlign: TextAlign.center,
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
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
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
              addAutomaticKeepAlives: true,
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
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 100,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey[300]!.withAlpha(100)),
            // Shimmer for Post Items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => Column(
                children: [
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey[300]!.withAlpha(50)),
                  const SizedBox(height: 5),
                ],
              ),
              itemCount: 3,
              itemBuilder: (_, __) => const PostShimmerItem(),
            ),
          ],
        ),
      ),
    );
  }
}
