import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/screens/posts/comments_likes_screens/comments_screen.dart';
import 'package:flutter/material.dart';

Future<dynamic> showCommentsModal(
  BuildContext context, {
  required String postId,
  required Stream<List<Map<String, dynamic>>> likesStream,
  required Stream<List<CommentModel>> commentsStream,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: CommentsScreen(
                postId: postId,
                scrollController: scrollController,
                likesStream: likesStream,
                commentsStream: commentsStream,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
