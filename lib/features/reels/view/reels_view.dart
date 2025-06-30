import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/features/reels/viewmodel/reels_cubit.dart';
import 'package:facebook_clone/models/reels_model.dart';
import 'package:facebook_clone/core/services/post_services/post_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/reels_player.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return BlocProvider(
      create: (_) =>
          ReelsCubit(postService: PostService(), userId: userId)..fetchReels(),
      child: BlocBuilder<ReelsCubit, ReelsState>(
        builder: (context, state) {
          if (state is ReelsLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is ReelsError) {
            return _buildError(context, state.message);
          }
          if (state is ReelsLoaded) {
            final reels = state.reels;
            if (reels.isEmpty) {
              return _buildError(context, 'You have no Reels yet.');
            }
            return _buildReelsPageView(context, reels, userId);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ondemand_video_outlined,
                size: 60, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start Share the reel with others!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => context.read<ReelsCubit>().fetchReels(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelsPageView(
      BuildContext context, List<ReelModel> reels, String userId) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          return ReelsPlayerWidget(
            chewieController: ChewieController(
              videoPlayerController: VideoPlayerController.networkUrl(
                  Uri.parse(reels[index].postVideoUrl)),
              looping: false,
              autoPlay: false,
              aspectRatio: 9 / 16,
            ),
            postService: PostService(),
            postId: reels[index].id,
            userId: userId,
            reels: reels[index],
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Delete this reel'),
                    content: const Text(
                        'Are you sure you want to delete this reel?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await PostService().deletePost(
                            postId: reels[index].id,
                            userId: userId,
                            isReel: true,
                          );
                          context.read<ReelsCubit>().fetchReels();
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
