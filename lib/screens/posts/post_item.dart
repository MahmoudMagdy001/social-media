import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/models/post_data_model.dart';
import 'package:facebook_clone/screens/posts/comments_screen.dart';
import 'package:facebook_clone/screens/posts/update_post_screen.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class PostItem extends StatefulWidget {
  final PostDataModel postData;
  final VoidCallback? onPostDeleted;

  const PostItem({
    super.key,
    required this.postData,
    this.onPostDeleted,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  final PostService _postService = PostService();
  final user = supabase.Supabase.instance.client.auth.currentUser;

  late Stream<List<CommentModel>> _commentsStream;
  late Stream<List<Map<String, dynamic>>> _likesStream;

  @override
  void initState() {
    super.initState();
    _commentsStream =
        _postService.getCommentsForPost(postId: widget.postData.documentId);

    _likesStream =
        _postService.getLikesForPost(postId: widget.postData.documentId);
  }

  Future<dynamic> showCommentsModal(BuildContext context) {
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
                  postId: widget.postData.documentId,
                  scrollController: scrollController,
                  likesStream: _likesStream,
                  commentsStream: _commentsStream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> showOptions(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        alignment: Alignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.check_circle,
          size: 60,
          color: Colors.green,
        ),
        title: const Text(
          'Success',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Post deleted successfully.',
          style: TextStyle(
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deletePost() async {
    return await _postService.deletePost(
        postId: widget.postData.documentId, userId: user!.id);
  }

  Future<void> addLike() async {
    return await _postService.addLike(
      postId: widget.postData.documentId,
      userId: user!.id,
    );
  }

  Future<void> removeLike() async {
    return await _postService.removeLike(
      postId: widget.postData.documentId,
      userId: user!.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    (widget.postData.documentId.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostUserSection(
            postData: widget.postData,
            onDelete: () async {
              await deletePost();
              widget.onPostDeleted?.call(); // trigger refresh
              if (context.mounted) {
                showOptions(context);
              }
            },
            onUpdate: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return UpdatePostScreen(post: widget.postData);
                },
              ));
            },
            currentUserUid: user?.id,
          ),
          const SizedBox(height: 12),
          // MARK text
          if (widget.postData.postText.isNotEmpty) ...[
            /// text of post ///
            CustomText(
              widget.postData.postText,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
          ],
          // MARK image
          if (widget.postData.postImageUrl != null) ...[
            /// image of post ///
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.postData.postImageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],

          InkWell(
              onTap: () {
                showCommentsModal(context);
                debugPrint(
                    "Comment button pressed for post: ${widget.postData.documentId}");
              },
              child: _buildReactsSection()),
          _buildInteractionButtons(
            likesStream: _likesStream,
          ),
        ],
      ),
    );
  }

  Widget _buildReactsSection() {
    final theme = Theme.of(context);

    return StreamBuilder<List<CommentModel>>(
      stream: _commentsStream,
      builder: (context, commentsSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _likesStream,
          initialData: [],
          builder: (context, likesSnapshot) {
            final likesCount = likesSnapshot.data?.length ?? 0;
            final commentsCount = commentsSnapshot.data?.length ?? 0;

            if (likesCount == 0 && commentsCount == 0) {
              return Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
              );
            }

            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: Row(
                children: [
                  if (likesCount != 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up_alt_rounded,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        CustomText('$likesCount',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  const Spacer(),
                  if (commentsCount > 0)
                    CustomText(
                      '$commentsCount ${commentsCount == 1 ? 'Comment' : 'Comments'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (widget.postData.sharesCount > 0) ...[
                    const SizedBox(width: 16),
                    CustomText('${widget.postData.sharesCount} Shares',
                        style: theme.textTheme.bodySmall),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInteractionButtons(
      {required Stream<List<Map<String, dynamic>>> likesStream}) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildLikeButton()),
          Expanded(child: _buildCommentButton(likesStream)),
          Expanded(child: _buildShareButton()),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    final theme = Theme.of(context);

    return StreamBuilder<bool>(
        stream: _postService.hasUserLikedPost(
            postId: widget.postData.documentId, userId: user!.id),
        builder: (context, asyncSnapshot) {
          final hasLiked = asyncSnapshot.data ?? false;
          if (hasLiked) {
            return TextButton.icon(
              onPressed: () async {
                await removeLike();
              },
              icon: Icon(Icons.thumb_up_alt_rounded,
                  color: theme.colorScheme.primary, size: 20),
              label: CustomText(
                'Like',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            );
          }
          return TextButton.icon(
            onPressed: () async {
              await addLike();
            },
            icon: Icon(Icons.thumb_up_alt_outlined,
                color: theme.colorScheme.onSurface.withAlpha(100), size: 20),
            label: CustomText(
              'Like',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
                fontWeight: FontWeight.normal,
              ),
            ),
          );
        });
  }

  Widget _buildCommentButton(Stream<List<Map<String, dynamic>>> likesStream) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: () {
        showCommentsModal(context);
      },
      icon: Icon(Icons.chat_bubble_outline_rounded,
          color: theme.colorScheme.onSurface.withAlpha(150), size: 20),
      label: CustomText(
        'Comment',
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
      ),
    );
  }

  Widget _buildShareButton() {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: () {
        debugPrint(
            "Share button pressed for post: ${widget.postData.documentId}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Share feature not implemented yet.")),
        );
      },
      icon: Icon(Icons.share_outlined,
          color: theme.colorScheme.onSurface.withAlpha(150), size: 20),
      label: CustomText(
        'Share',
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
      ),
    );
  }
}

// --- Helper Widgets ---

class _PostUserSection extends StatelessWidget {
  final PostDataModel postData;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final String? currentUserUid;

  const _PostUserSection({
    required this.postData,
    required this.onDelete,
    required this.onUpdate,
    required this.currentUserUid,
  });

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc();
    final postTime = dateTime.toUtc();
    final difference = now.difference(postTime);

    // If the difference is negative (post time is in the future), return the actual time
    if (difference.isNegative) {
      final hour = postTime.hour;
      final minute = postTime.minute;
      final period = hour < 12 ? 'AM' : 'PM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }

    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 365) return '${(difference.inDays / 7).floor()}w';
    return '${(difference.inDays / 365).floor()}y';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isOwner = currentUserUid == postData.userId;

    return Row(
      children: [
        _ProfileImage(imageUrl: postData.profileImageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomText(
                    postData.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              CustomText(
                _getTimeAgo(postData.postTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        if (isOwner)
          _PostOptionsMenu(
            onDelete: onDelete,
            onUpdate: onUpdate,
          ),
      ],
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final String? imageUrl;

  const _ProfileImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 28,
      backgroundColor: theme.colorScheme.primaryContainer.withAlpha(100),
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: !hasImage
          ? Icon(Icons.person,
              size: 28, color: theme.colorScheme.onPrimaryContainer)
          : null,
    );
  }
}

class _PostOptionsMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const _PostOptionsMenu({required this.onDelete, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded,
          color: theme.colorScheme.onSurface.withAlpha(180)),
      tooltip: "Post options",
      onSelected: (value) {
        debugPrint("Post option selected: $value");
        if (value == 'update') {
          onUpdate();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'update',
          child: const Row(children: [
            Icon(Icons.edit_outlined),
            SizedBox(width: 8),
            Text('Edit Post')
          ]),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Text('Delete Post',
                style: TextStyle(color: theme.colorScheme.error))
          ]),
        ),
      ],
    );
  }
}
