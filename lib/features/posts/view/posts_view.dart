import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/features/posts/viewmodel/posts_cubit.dart';
import 'package:facebook_clone/core/services/post_services/post_service.dart';
import 'package:facebook_clone/core/widgets/shimmer.dart';
import 'package:facebook_clone/core/widgets/custom_text.dart';
import 'package:facebook_clone/features/layout/model/layout_model.dart';
import 'package:facebook_clone/core/utlis/animation_navigate.dart';

import 'widgets/create_post_screen.dart';
import 'widgets/posts_list.dart';

class PostsScreen extends StatelessWidget {
  final UserModel user;
  const PostsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PostsCubit(postService: PostService(), userId: user.id)..fetchPosts(),
      child: BlocBuilder<PostsCubit, PostsState>(
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            context.read<PostsCubit>().fetchPosts(),
                        child: _buildPostsContent(context, state),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: 'Create Post',
              onPressed: () async {
                await navigateWithTransition(
                  context,
                  const CreatePostScreen(),
                  type: TransitionType.slideFromBottom,
                );
                context.read<PostsCubit>().fetchPosts();
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsContent(BuildContext context, PostsState state) {
    if (state is PostsLoading) {
      return const ListShimmer();
    }
    if (state is PostsLoaded) {
      final posts = state.posts;
      if (posts.isEmpty) {
        return _buildEmptyState(context);
      }
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          PostsList(
            posts: posts,
            onRefresh: () => context.read<PostsCubit>().fetchPosts(),
            postService: PostService(),
            userId: user.id,
            onPostDeleted: () => context.read<PostsCubit>().fetchPosts(),
            user: user,
          )
        ],
      );
    }
    if (state is PostsError) {
      return Center(child: Text(state.message));
    }
    return _buildEmptyState(context, scrollable: true);
  }

  Widget _buildEmptyState(BuildContext context, {bool scrollable = false}) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 60, color: Colors.grey[500]),
          const SizedBox(height: 16),
          CustomText(
            'You have no Posts yet.',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          CustomText(
            'Be the first to post!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              context.read<PostsCubit>().fetchPosts();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    return scrollable
        ? CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: content,
              ),
            ],
          )
        : content;
  }
}
