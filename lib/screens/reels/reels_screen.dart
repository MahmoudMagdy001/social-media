import 'package:facebook_clone/models/reels_model.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PostService _postService = PostService();
  List<ReelModel> reels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReels(); // Start fetching when the widget is initialized
  }

  Future<void> fetchReels() async {
    try {
      List<ReelModel> fetchedReels = await _postService.getReels();
      setState(() {
        reels = fetchedReels;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to fetch reels: $e");
      // Optionally handle error state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : reels.isEmpty
                ? const Center(
                    child: Text(
                      "No reels available",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : PageView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: reels.length,
                    itemBuilder: (context, index) {
                      return VideoPlayerScreen(
                          videoUrl: reels[index].postVideoUrl);
                    },
                  ),
      ),
    );
  }
}
