import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';

/// Stateless widget to display video using a pre-initialized ChewieController.
class VideoPlayerScreen extends StatelessWidget {
  final ChewieController chewieController;

  const VideoPlayerScreen({super.key, required this.chewieController});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Chewie(controller: chewieController),
    );
  }
}
