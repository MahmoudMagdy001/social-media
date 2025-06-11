import 'package:facebook_clone/models/reels_model.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/reels_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  _ReelsScreenState createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PostService _postService = PostService();
  List<ReelModel> reels = [];
  List<VideoPlayerController> _videoControllers = [];
  List<ChewieController> _chewieControllers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReels();
  }

  Future<void> loadReels() async {
    try {
      // 1. Fetch reels from your service
      reels = await _postService.getReels();

      // 2. Initialize video and chewie controllers for each reel
      for (var reel in reels) {
        final videoController =
            VideoPlayerController.networkUrl(Uri.parse(reel.postVideoUrl));
        await videoController.initialize();

        final chewieController = ChewieController(
          videoPlayerController: videoController,
          autoPlay: false,
          looping: false,
          aspectRatio: videoController.value.aspectRatio,
        );

        _videoControllers.add(videoController);
        _chewieControllers.add(chewieController);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading reels: $e");
    }
  }

  @override
  void dispose() {
    for (var controller in _videoControllers) {
      controller.dispose();
    }
    for (var chewieController in _chewieControllers) {
      chewieController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _chewieControllers.length,
        itemBuilder: (context, index) {
          return VideoPlayerScreen(
            chewieController: _chewieControllers[index],
          );
        },
      ),
    );
  }
}
