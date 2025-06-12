import 'package:facebook_clone/screens/posts/create_update_post/create_post_screen.dart';
import 'package:flutter/material.dart';

import '../../models/post_data_model.dart';
import 'posts_section/post_item.dart';
import 'posts_section/post_shimmer_item.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/custom_text.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen>
    with AutomaticKeepAliveClientMixin<PostsScreen> {
  final PostService _postService = PostService();
  late Future<List<PostDataModel>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.getPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = _postService.getPosts();
    });
  }

  @override
  bool get wantKeepAlive => true;

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
            builder: (context) => CreatePostScreen(),
          ));
          if (result == true) {
            _refreshPosts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostsList() {
    return FutureBuilder<List<PostDataModel>>(
      future: _postsFuture,
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
          posts: posts,
          onPostDeleted: _refreshPosts,
          onRefresh: () async {
            _refreshPosts();
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

  const _PostsListView({
    required this.posts,
    this.onPostDeleted,
    required this.onRefresh,
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
              (context, index) {
                final post = posts[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) => Column(
        children: [
          const SizedBox(height: 10),
          Divider(
            color: Theme.of(context).dividerColor.withAlpha(50),
          ),
          const SizedBox(height: 5),
        ],
      ),
      itemCount: 5,
      itemBuilder: (_, __) => const PostShimmerItem(),
    );
  }
}
