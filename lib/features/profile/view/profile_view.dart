import 'package:facebook_clone/core/widgets/custom_text.dart';
import 'package:facebook_clone/core/widgets/shimmer.dart';
import 'package:facebook_clone/features/layout/model/layout_model.dart';
import 'package:facebook_clone/features/profile/viewmodel/profile_cubit.dart';
import 'package:facebook_clone/features/profile/viewmodel/profile_state.dart';
import 'package:facebook_clone/screens/posts/post_section/posts_list.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/post_data_model.dart';

class UserProfileView extends StatelessWidget {
  final UserModel currentUser;
  final String userId;
  final String displayName;
  final String profileImage;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.currentUser,
    required this.displayName,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit()..loadUserProfile(userId),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state.status == ProfileStatus.profileloading) {
                return const ProfileShimmer();
              }

              if (state.status == ProfileStatus.profileerror) {
                return Center(
                    child:
                        CustomText(state.message ?? 'Error loading profile'));
              }

              if (state.status == ProfileStatus.profilesuccess) {
                final isOwner = currentUser.id == userId;
                final posts = state.data['posts'] as List<PostDataModel>;
                final friends =
                    state.data['friends'] as List<Map<String, dynamic>>;

                return _PostsListView(
                  posts: posts,
                  onRefresh: () =>
                      context.read<ProfileCubit>().loadUserProfile(userId),
                  profileImage: profileImage,
                  displayName: displayName,
                  friendsList: friends,
                  // friendService: context.read<ProfileCubit>().friendService,
                  postService: context.read<ProfileCubit>().postService,
                  userId: userId,
                  isOwner: isOwner,
                  currentUser: currentUser,
                  onPostDeleted: () =>
                      context.read<ProfileCubit>().loadUserProfile(userId),
                );
              }

              return const SizedBox(); // For ProfileStatus.initial
            },
          ),
        ),
      ),
    );
  }
}

class _PostsListView extends StatelessWidget {
  final List<PostDataModel> posts;
  final VoidCallback onPostDeleted;
  final Future<void> Function() onRefresh;
  final String profileImage;
  final String displayName;
  final List<Map<String, dynamic>> friendsList;
  // final FriendService friendService;
  final PostService postService;
  final String userId;
  final bool isOwner;
  final UserModel currentUser;

  const _PostsListView({
    required this.posts,
    required this.onRefresh,
    required this.profileImage,
    required this.displayName,
    required this.friendsList,
    // required this.friendService,
    required this.postService,
    required this.onPostDeleted,
    required this.userId,
    required this.isOwner,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 150,
            pinned: true,
            floating: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 25),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(profileImage),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(
                  profileImage: profileImage,
                  displayName: displayName,
                  friendsList: friendsList,
                  // friendService: friendService,
                  isOwner: isOwner,
                ),
                const Divider(),
              ],
            ),
          ),
          if (posts.isEmpty)
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
              user: currentUser,
            ),
        ],
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String profileImage;
  final String displayName;
  final List<Map<String, dynamic>> friendsList;
  // final FriendService friendService;
  final bool isOwner;

  const ProfileHeader({
    super.key,
    required this.profileImage,
    required this.displayName,
    required this.friendsList,
    // required this.friendService,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final friendsCount = friendsList.length;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                friendsCount.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              CustomText(friendsCount == 1 ? 'Friend' : 'Friends'),
              const Spacer(),
              InkWell(
                onTap: () {
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (context) => FriendsList(
                  //       friendsList: friendsList,
                  //       friendService: friendService,
                  //       isOwner: isOwner,
                  //     ),
                  //   ),
                  // );
                },
                child: CustomText(
                  'show all friends',
                  style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (friendsList.isNotEmpty)
            SizedBox(
              height: friendsCount == 1 ? 142 : 330,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friendsList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: friendsCount == 1 ? 1 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final friend = friendsList[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: NetworkImage(friend['profile_image'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 100,
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
            )
        ],
      ),
    );
  }
}
