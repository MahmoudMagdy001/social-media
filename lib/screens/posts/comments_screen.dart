import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/screens/posts/likes_screen.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class CommentsScreen extends StatefulWidget {
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
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  final supabase.User? currentUser =
      supabase.Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> addComment(String value) async {
    return await _postService.addCommentToPost(
        postId: widget.postId, commentText: value.trim(), user: currentUser!);
  }

  @override
  Widget build(BuildContext context) {
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
                      stream: widget.likesStream,
                      builder: (context, snapshot) {
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) {
                                return LikesScreen(
                                  likesStream: widget.likesStream,
                                );
                              },
                            ));
                          },
                          child: Row(
                            children: [
                              Text(
                                '${snapshot.data?.length ?? 0} likes',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
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
              controller: widget.scrollController,
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: 1,
                    (context, index) {
                      return StreamBuilder<List<CommentModel>>(
                        initialData: [],
                        stream: widget.commentsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }
                          final comments = snapshot.data ?? [];
                          return Column(
                            children: [
                              ...comments.asMap().entries.map((entry) {
                                final index = entry.key;
                                final comment = entry.value;
                                return CommentsList(
                                  comment: comment,
                                  currentUser: currentUser,
                                  postService: _postService,
                                  widget: widget,
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
          buildInputField(),
        ],
      ),
    );
  }

  Padding buildInputField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
      child: TextFormField(
        controller: _commentController,
        onFieldSubmitted: (value) async {
          if (value.isNotEmpty) {
            await addComment(value);
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
                await _postService.addCommentToPost(
                  postId: widget.postId,
                  commentText: _commentController.text.trim(),
                  user: currentUser!,
                );
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
    required PostService postService,
    required this.widget,
    required this.index,
    required this.comments,
  }) : _postService = postService;

  final CommentModel comment;
  final supabase.User? currentUser;
  final PostService _postService;
  final CommentsScreen widget;
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
                    Text(comment.username,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      comment.timestamp.toLocal().toString(),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                subtitle: Text(comment.commentText),
              ),
            ),
            if (currentUser!.id == comment.userId)
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
                    child: Text('Delete',
                        style: TextStyle(
                          color: Colors.red,
                        )),
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
                                _postService.deleteComment(
                                  commentId: comment.commentId,
                                  postId: widget.postId,
                                );
                                Navigator.of(context).pop();
                              },
                              child: Text('Delete',
                                  style: TextStyle(
                                    color: Colors.red,
                                  )),
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
