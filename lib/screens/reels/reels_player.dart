import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/widgets/comments_modal.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';

class ReelsPlayerWidget extends StatefulWidget {
  final PostService postService;
  final ChewieController chewieController;
  final String postId;
  final String userId;

  const ReelsPlayerWidget({
    super.key,
    required this.chewieController,
    required this.postService,
    required this.postId,
    required this.userId,
  });

  @override
  State<ReelsPlayerWidget> createState() => _ReelsPlayerWidgetState();
}

class _ReelsPlayerWidgetState extends State<ReelsPlayerWidget> {
  late Stream<List<CommentModel>> _commentsStream;
  late Stream<List<Map<String, dynamic>>> _likesStream;

  @override
  void initState() {
    super.initState();
    _commentsStream =
        widget.postService.getCommentsForPost(postId: widget.postId);

    _likesStream = widget.postService.getLikesForPost(postId: widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Chewie(controller: widget.chewieController),
        Positioned(
          bottom: 80,
          right: 5,
          child: Column(
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                stream:
                    widget.postService.getLikesForPost(postId: widget.postId),
                builder: (context, snapshot) {
                  final likes = snapshot.data ?? [];

                  return StreamBuilder<bool>(
                    stream: widget.postService.hasUserLikedPost(
                      postId: widget.postId,
                      userId: widget.userId,
                    ),
                    builder: (context, snapshot) {
                      final isLiked = snapshot.data ?? false;

                      return _ActionButton(
                        icon: isLiked
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        iconColor: isLiked ? Colors.blue : Colors.white,
                        label: likes.length.toString(),
                        onPressed: () async {
                          try {
                            if (isLiked) {
                              await widget.postService.removeLike(
                                postId: widget.postId,
                                userId: widget.userId,
                              );
                            } else {
                              await widget.postService.addLike(
                                postId: widget.postId,
                                userId: widget.userId,
                              );
                            }
                          } catch (e) {
                            debugPrint('Error toggling like: $e');
                          }
                        },
                      );
                    },
                  );
                },
              ),
              _ActionButton(
                icon: Icons.comment_outlined,
                iconColor: Colors.white,
                label: 'Comment',
                onPressed: () {
                  showCommentsModal(
                    context,
                    postId: widget.postId,
                    likesStream: _likesStream,
                    commentsStream: _commentsStream,
                  );
                  debugPrint('Comment tapped!');
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),

        // Like & Comment buttons
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor ?? Colors.black, size: 30),
          onPressed: onPressed,
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }
}
