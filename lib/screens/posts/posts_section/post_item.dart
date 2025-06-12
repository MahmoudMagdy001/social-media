// ignore_for_file: unnecessary_null_comparison

import 'package:cached_network_image/cached_network_image.dart';
import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/models/post_data_model.dart';
import 'package:facebook_clone/screens/posts/create_update_post/update_post_screen.dart';
import 'package:facebook_clone/screens/posts/posts_section/options_update_delete.dart';
import 'package:facebook_clone/screens/posts/posts_section/reacts_section.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/comments_modal.dart';
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
  late Stream<bool> _hasUserLikedPost;

  late PostDataModel _postData;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    _postData = widget.postData;

    _commentsStream =
        _postService.getCommentsForPost(postId: _postData.documentId);
    _likesStream = _postService.getLikesForPost(postId: _postData.documentId);
    _hasUserLikedPost = _postService.hasUserLikedPost(
      postId: _postData.documentId,
      userId: user?.id ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postData.documentId != widget.postData.documentId) {
      _initializeStreams();
    }
  }

  Future<void> _deletePost() async {
    if (user == null) return;
    await _postService.deletePost(postId: _postData.postId, userId: user!.id);
    widget.onPostDeleted?.call();
    if (mounted) {
      showOptions(context);
    }
  }

  Future<void> _toggleLike(bool liked) async {
    if (user == null) return;
    liked
        ? await _postService.removeLike(
            postId: _postData.postId, userId: user!.id)
        : await _postService.addLike(
            postId: _postData.postId, userId: user!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostUserSection(
            postData: _postData,
            onDelete: _deletePost,
            onUpdate: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UpdatePostScreen(post: _postData),
                ),
              );
            },
            currentUserUid: user?.id,
          ),
          const SizedBox(height: 12),
          if (_postData.postText.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  _postData.postText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
              ],
            ),
          if (_postData.postImageUrl != null)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _postData.postImageUrl!,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          InkWell(
            onTap: () {
              showCommentsModal(
                context,
                postId: _postData.documentId,
                likesStream: _likesStream,
                commentsStream: _commentsStream,
              );
            },
            child: reactsSection(
              context,
              commentsStream: _commentsStream,
              likesStream: _likesStream,
              sharesCount: _postData.sharesCount,
            ),
          ),
          _buildInteractionButtons(),
        ],
      ),
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
      stream: _hasUserLikedPost,
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
          postId: _postData.documentId,
          likesStream: _likesStream,
          commentsStream: _commentsStream,
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Image
        CircleAvatar(
          radius: 22,
          backgroundImage: postData.profileImageUrl != null
              ? CachedNetworkImageProvider(postData.profileImageUrl)
              : null,
          child: postData.profileImageUrl == null
              ? const Icon(Icons.person, size: 24)
              : null,
        ),
        const SizedBox(width: 10),

        // Name & Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                postData.username,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              CustomText(
                postData.postTime
                    .toUtc()
                    .toString(), // format this in PostDataModel or format here
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
                onDelete();
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
    );
  }
}
