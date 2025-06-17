import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/models/post_data_model.dart';
import 'package:facebook_clone/screens/posts/posts_section/post_item.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class PostsList extends StatelessWidget {
  final List<PostDataModel> posts;
  final void Function()? onPostDeleted;
  final void Function() onRefresh;
  final PostService postService;
  final supabase.User user;

  const PostsList({
    super.key,
    required this.posts,
    this.onPostDeleted,
    required this.onRefresh,
    required this.postService,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    late Stream<List<CommentModel>> commentsStream;
    late Stream<List<Map<String, dynamic>>> likesStream;
    late Stream<bool> hasUserLikedPost;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = posts[index];

          commentsStream =
              postService.getCommentsForPost(postId: post.documentId);
          likesStream = postService.getLikesForPost(postId: post.documentId);
          hasUserLikedPost = postService.hasUserLikedPost(
            postId: post.documentId,
            userId: user.id,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PostItem(
                postData: post,
                onPostDeleted: onPostDeleted,
                postService: postService,
                user: user,
                commentsStream: commentsStream,
                likesStream: likesStream,
                hasUserLikedPost: hasUserLikedPost,
                update: onRefresh,
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
    );
  }
}
