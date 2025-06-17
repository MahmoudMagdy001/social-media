import 'package:cached_network_image/cached_network_image.dart';
import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/models/post_data_model.dart';
import 'package:facebook_clone/screens/posts/create_update_post/update_post_screen.dart';
import 'package:facebook_clone/screens/posts/posts_section/update_delete_options.dart';
import 'package:facebook_clone/screens/posts/posts_section/reacts_section.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/comments_modal.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class PostItem extends StatefulWidget {
  final PostDataModel postData;
  final VoidCallback? onPostDeleted;
  final PostService postService;
  final supabase.User user;
  final Stream<List<CommentModel>> commentsStream;
  final Stream<List<Map<String, dynamic>>> likesStream;
  final Stream<bool> hasUserLikedPost;
  final void Function()? update;

  const PostItem({
    super.key,
    required this.postData,
    this.onPostDeleted,
    required this.postService,
    required this.user,
    required this.commentsStream,
    required this.likesStream,
    required this.hasUserLikedPost,
    this.update,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postData.documentId != widget.postData.documentId) {}
  }

  Future<void> _deletePost() async {
    await widget.postService.deletePost(
      postId: widget.postData.postId,
      userId: widget.user.id,
      isReel: false,
    );
    widget.onPostDeleted?.call();
    if (mounted) {
      showOptions(context);
    }
  }

  Future<void> _toggleLike(bool liked) async {
    liked
        ? await widget.postService.removeLike(
            postId: widget.postData.postId,
            userId: widget.user.id,
          )
        : await widget.postService.addLike(
            postId: widget.postData.postId,
            userId: widget.user.id,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PostUserSection(
          postData: widget.postData,
          onDelete: _deletePost,
          onUpdate: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UpdatePostScreen(post: widget.postData),
              ),
            );
            if (result == true) {
              widget.update!();
            }
          },
          currentUserUid: widget.user.id,
        ),
        const SizedBox(height: 12),
        if (widget.postData.postText.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: CustomText(
                  widget.postData.postText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        if (widget.postData.postImageUrl != null)
          Column(
            children: [
              CachedNetworkImage(
                width: double.infinity,
                imageUrl: widget.postData.postImageUrl!,
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
              const SizedBox(height: 12),
            ],
          ),
        InkWell(
          onTap: () {
            showCommentsModal(
              context,
              postId: widget.postData.documentId,
              likesStream: widget.likesStream,
              commentsStream: widget.commentsStream,
            );
          },
          child: reactsSection(
            context,
            commentsStream: widget.commentsStream,
            likesStream: widget.likesStream,
            sharesCount: widget.postData.sharesCount,
          ),
        ),
        _buildInteractionButtons(),
      ],
    );
  }

  Widget _buildInteractionButtons() {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildLikeButton()),
          Expanded(child: _buildCommentButton()),
          Expanded(child: _buildShareButton()),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    final theme = Theme.of(context);

    return StreamBuilder<bool>(
      stream: widget.hasUserLikedPost,
      builder: (context, snapshot) {
        final hasLiked = snapshot.data ?? false;

        return TextButton.icon(
          onPressed: () => _toggleLike(hasLiked),
          icon: Icon(
            hasLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
            color: hasLiked
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(100),
            size: 20,
          ),
          label: CustomText(
            'Like',
            style: theme.textTheme.labelLarge?.copyWith(
              color: hasLiked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withAlpha(150),
              fontWeight: hasLiked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentButton() {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: () {
        showCommentsModal(
          context,
          postId: widget.postData.documentId,
          likesStream: widget.likesStream,
          commentsStream: widget.commentsStream,
        );
      },
      icon: Icon(
        Icons.chat_bubble_outline_rounded,
        color: theme.colorScheme.onSurface.withAlpha(150),
        size: 20,
      ),
      label: CustomText(
        'Comment',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(150),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Share feature not implemented yet.")),
        );
      },
      icon: Icon(
        Icons.share_outlined,
        color: theme.colorScheme.onSurface.withAlpha(150),
        size: 20,
      ),
      label: CustomText(
        'Share',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(150),
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final isOwner = postData.userId == currentUserUid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          CircleAvatar(
            radius: 27,
            backgroundImage:
                CachedNetworkImageProvider(postData.profileImageUrl),
          ),
          const SizedBox(width: 10),

          // Name & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  postData.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                CustomText(
                  postData.timeAgo,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),

          // More Options for Post Owner
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onUpdate();
                } else if (value == 'delete') {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Delete Post'),
                        content: Text('Are you sure to delete this post?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDelete();
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    )),
              ],
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
    );
  }
}
