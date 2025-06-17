import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:flutter/material.dart';

Widget reactsSection(
  BuildContext context, {
  required Stream<List<CommentModel>> commentsStream,
  required Stream<List<Map<String, dynamic>>> likesStream,
  required int sharesCount,
}) {
  final theme = Theme.of(context);

  return StreamBuilder<List<CommentModel>>(
    stream: commentsStream,
    builder: (context, commentsSnapshot) {
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: likesStream,
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
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
                if (sharesCount > 0) ...[
                  const SizedBox(width: 16),
                  CustomText('$sharesCount Shares',
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
