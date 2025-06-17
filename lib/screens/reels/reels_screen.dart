import 'package:facebook_clone/models/reels_model.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/screens/reels/reels_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PostService _postService = PostService();
  final PageController _pageController = PageController();

  final List<VideoPlayerController> _videoControllers = [];
  final List<ChewieController> _chewieControllers = [];

  List<ReelModel> reels = [];
  bool isLoading = true;
  bool hasError = false;
  int currentPageIndex = 0;

  final String userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      final fetchedReels = await _postService.getReels();

      // Cleanup old controllers if any (important for reloads)
      _disposeControllers();

      for (final reel in fetchedReels) {
        final videoController = VideoPlayerController.networkUrl(
          Uri.parse(reel.postVideoUrl),
        );
        await videoController.initialize();

        final chewieController = ChewieController(
          videoPlayerController: videoController,
          looping: false,
          autoPlay: false,
          aspectRatio: videoController.value.aspectRatio,
        );

        _videoControllers.add(videoController);
        _chewieControllers.add(chewieController);
      }

      if (!mounted) return;

      setState(() {
        reels = fetchedReels;
        isLoading = false;
        hasError = false;
      });

      if (_videoControllers.isNotEmpty) {
        _videoControllers[0].play();
      }
    } catch (e) {
      debugPrint("Error loading reels: $e");

      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });

    for (int i = 0; i < _videoControllers.length; i++) {
      if (i == index) {
        _videoControllers[i].play();
      } else {
        _videoControllers[i].pause();
        _videoControllers[i].seekTo(Duration.zero); // optional: reset
      }
    }
  }

  void _disposeControllers() {
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    for (final chewie in _chewieControllers) {
      chewie.dispose();
    }
    _videoControllers.clear();
    _chewieControllers.clear();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError || reels.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('There is no reels to play'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    hasError = false;
                  });
                  _loadReels();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          if (index >= _chewieControllers.length) {
            return const Center(child: Text('Invalid reel.'));
          }

          return AnimatedOpacity(
            opacity: currentPageIndex == index ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: ReelsPlayerWidget(
              chewieController: _chewieControllers[index],
              postService: _postService,
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
                        'Are you sure you want to delete this reel?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close dialog first
                            setState(() {
                              isLoading = true;
                            });

                            await _postService.deletePost(
                              postId: reels[index].id,
                              userId: userId,
                              isReel: true,
                            );

                            _loadReels(); // Reload reels
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
