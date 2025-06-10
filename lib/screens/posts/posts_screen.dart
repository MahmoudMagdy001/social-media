import 'package:facebook_clone/screens/posts/create_post_screen.dart';
import 'package:flutter/material.dart';

import '../../models/post_data_model.dart';
import 'post_item.dart';
import 'post_shimmer_item.dart';
import 'package:facebook_clone/services/auth_services/auth_service.dart'; // Assuming this exists
import 'package:facebook_clone/services/post_services/post_service.dart'; // Or your actual PostService file
import 'package:facebook_clone/widgets/custom_text.dart';

class PostsScreen extends StatefulWidget {
  final AuthService authService;

  const PostsScreen({
    super.key,
    required this.authService,
  });

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen>
    with AutomaticKeepAliveClientMixin<PostsScreen> {
  @override
  bool get wantKeepAlive => true;
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Expanded(
                child: _buildPostsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Post',
        onPressed: () async {
          final result = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return CreatePostScreen();
            },
          ));
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<List<PostDataModel>>(
      stream: _postService.getPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ShimmerList();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: CustomText('No posts available or failed to load.'),
          );
        }

        final posts = snapshot.data!;

        if (posts.isEmpty) {
          return const Center(
            child: CustomText('No posts yet. Be the first to post!'),
          );
        }

        return _PostsListView(
          onPostDeleted: () {
            setState(() {});
          },
          posts: posts,
        );
      },
    );
  }
}

class _PostsListView extends StatelessWidget {
  final List<PostDataModel> posts;
  final void Function()? onPostDeleted;

  const _PostsListView({
    required this.posts,
    this.onPostDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: posts.length,
            addAutomaticKeepAlives: true,
            (context, index) {
              return Column(
                children: [
                  PostItem(
                    postData: posts[index],
                    onPostDeleted: onPostDeleted,
                  ),
                  if (index < posts.length - 1)
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        Divider(),
                        const SizedBox(height: 5),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) => Column(
        children: [
          const SizedBox(height: 10),
          Divider(
            color: Theme.of(context).dividerColor.withAlpha(50),
          ),
          const SizedBox(height: 5),
        ],
      ),
      itemCount: 5, // Show a few shimmer items
      itemBuilder: (_, __) => const PostShimmerItem(),
    );
  }
}
