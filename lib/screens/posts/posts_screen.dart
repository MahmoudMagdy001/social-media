import 'package:facebook_clone/screens/posts/create_update_post/create_post_screen.dart';
import 'package:facebook_clone/screens/posts/posts_section/posts_list.dart';
import 'package:facebook_clone/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../models/post_data_model.dart';
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

  final user = supabase.Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.getFriendsPosts(user!.id);
  }

  void refreshPosts() {
    setState(() {
      _postsFuture = _postService.getFriendsPosts(user!.id);
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
          padding: const EdgeInsets.symmetric(vertical: 10),
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
            refreshPosts();
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
          return const ListShimmer();
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

        return RefreshIndicator(
          onRefresh: () async {
            refreshPosts();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              PostsList(
                posts: posts,
                onRefresh: () async {
                  refreshPosts();
                },
                postService: _postService,
                user: user!,
              )
            ],
          ),
        );
      },
    );
  }
}
