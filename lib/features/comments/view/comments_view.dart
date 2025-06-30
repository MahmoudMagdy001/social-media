import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/features/comments/viewmodel/comments_cubit.dart';
import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/core/services/post_services/post_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class CommentsScreen extends StatelessWidget {
  final String postId;
  final ScrollController scrollController;
  final Stream<List<Map<String, dynamic>>> likesStream;
  final Stream<List<CommentModel>> commentsStream;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.scrollController,
    required this.likesStream,
    required this.commentsStream,
  });

  @override
  Widget build(BuildContext context) {
    final user = supabase.Supabase.instance.client.auth.currentUser;
    return BlocProvider(
      create: (_) =>
          CommentsCubit(postService: PostService(), postId: postId, user: user)
            ..fetchComments(),
      child: BlocBuilder<CommentsCubit, CommentsState>(
        builder: (context, state) {
          return Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StreamBuilder<List<Map<String, dynamic>>>(
                            initialData: [],
                            stream: likesStream,
                            builder: (context, snapshot) {
                              return InkWell(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    Text(
                                      '${snapshot.data?.length ?? 0} likes',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 18),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                Flexible(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: 1,
                          (context, index) {
                            return StreamBuilder<List<CommentModel>>(
                              initialData: [],
                              stream: commentsStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: {snapshot.error}'));
                                }
                                final comments = snapshot.data ?? [];
                                return Column(
                                  children: [
                                    ...comments.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final comment = entry.value;
                                      return CommentsList(
                                        comment: comment,
                                        currentUser: user,
                                        postService: PostService(),
                                        postId: postId,
                                        index: index,
                                        comments: comments,
                                      );
                                    }),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                buildInputField(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding buildInputField(BuildContext context, dynamic user) {
    final TextEditingController _commentController = TextEditingController();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
      child: TextFormField(
        controller: _commentController,
        onFieldSubmitted: (value) async {
          if (value.isNotEmpty) {
            context.read<CommentsCubit>().addComment(value);
            _commentController.clear();
          }
        },
        decoration: InputDecoration(
          hintText: 'Add a comment...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          suffixIcon: IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              if (_commentController.text.trim().isNotEmpty) {
                context
                    .read<CommentsCubit>()
                    .addComment(_commentController.text.trim());
                _commentController.clear();
              }
            },
          ),
        ),
      ),
    );
  }
}

class CommentsList extends StatelessWidget {
  const CommentsList({
    super.key,
    required this.comment,
    required this.currentUser,
    required this.postService,
    required this.postId,
    required this.index,
    required this.comments,
  });

  final CommentModel comment;
  final dynamic currentUser;
  final PostService postService;
  final String postId;
  final int index;
  final List<CommentModel> comments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(comment.profileImageUrl),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      comment.createdAt.toString().substring(0, 16),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                subtitle: Text(comment.commentText),
              ),
            ),
            if (currentUser != null && currentUser.id == comment.userId)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz),
                tooltip: 'More options',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                  } else if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Delete Comment'),
                          content: Text(
                              'Are you sure you want to delete this comment?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                postService.deleteComment(
                                  commentId: comment.commentId,
                                  postId: postId,
                                );
                                Navigator.of(context).pop();
                              },
                              child: Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              )
          ],
        ),
        if (index < comments.length - 1) Divider(),
      ],
    );
  }
}
