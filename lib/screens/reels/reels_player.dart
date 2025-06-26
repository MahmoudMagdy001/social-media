import 'package:cached_network_image/cached_network_image.dart';
import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/core/widgets/comments_modal.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';

import '../../models/reels_model.dart';

class ReelsPlayerWidget extends StatefulWidget {
  final PostService postService;
  final ChewieController chewieController;
  final String postId;
  final String userId;
  final ReelModel reels;
  final void Function() onPressed;

  const ReelsPlayerWidget({
    super.key,
    required this.chewieController,
    required this.postService,
    required this.postId,
    required this.userId,
    required this.reels,
    required this.onPressed,
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
    return GestureDetector(
      onLongPress: widget.onPressed,
      onTap: () {},
      child: Stack(
        alignment: Alignment.bottomCenter,
        // Ensures Stack sizes to its children
        children: [
          Chewie(controller: widget.chewieController),
          // UI elements positioned from the bottom
          Positioned(
            bottom: 65, // Adjusted bottom
            right: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Important for positioned elements
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
                const SizedBox(height: 10),
                // Spacing between action buttons
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
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 65,
            // Adjusted bottom
            right: 80,
            // Add some right padding to avoid overlap with action buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              // Important for positioned elements
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20, // Slightly smaller avatar
                      backgroundColor: Colors.grey[300],
                      backgroundImage: CachedNetworkImageProvider(
                        widget.reels.profileImageUrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      // Allow text to take available space and wrap if needed
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.reels.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 1.0, color: Colors.black54)
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            // Consider formatting the date/time
                            widget.reels.createdAt.toString().substring(0, 16),
                            // Example: Show only date part
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              shadows: [
                                Shadow(blurRadius: 1.0, color: Colors.black54)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget
                    .reels.postText.isNotEmpty) // Only show if text exists
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    // Ensure text doesn't go under buttons too much
                    child: Text(
                      widget.reels.postText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        shadows: [
                          Shadow(blurRadius: 1.0, color: Colors.black54)
                        ],
                      ),
                      maxLines: 2, // Limit lines for post text
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor ?? Colors.white, size: 28),
          // Consistent icon color
          onPressed: onPressed,
        ),
        if (label.isNotEmpty) // Only show label if it's not empty
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(blurRadius: 1.0, color: Colors.black54)],
            ),
          ),
      ],
    );
  }
}
