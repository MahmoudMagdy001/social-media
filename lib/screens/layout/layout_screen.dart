import 'package:facebook_clone/screens/friends/friends_screen.dart';
import 'package:facebook_clone/screens/menu/menu_screen.dart';
import 'package:facebook_clone/screens/posts/create_update_post/create_post_screen.dart';
import 'package:facebook_clone/screens/reels/reels_screen.dart';
import 'package:facebook_clone/widgets/custom_icon_button.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:flutter/material.dart';

import '../../services/auth_services/auth_service.dart';
import '../posts/posts_screen.dart';

class LayoutScreen extends StatefulWidget {
  final AuthService authService;

  const LayoutScreen({
    super.key,
    required this.authService,
  });

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update UI on tab change
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _showFab => _tabController.index == 0 || _tabController.index == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _showFab
          ? FloatingActionButton(
              tooltip: 'Create Post',
              onPressed: () async {
                final result =
                    await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CreatePostScreen(),
                ));
                if (result == true) {}
              },
              child: const Icon(Icons.add),
            )
          : null,
      appBar: AppBar(
        centerTitle: false,
        title: CustomText(
          'Social Media',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 4.0, color: Colors.blue),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined, size: 32)),
            Tab(icon: Icon(Icons.ondemand_video_outlined, size: 32)),
            Tab(icon: Icon(Icons.storefront_outlined, size: 32)),
            Tab(icon: Icon(Icons.menu_outlined, size: 32)),
          ],
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        actions: [
          CustomIconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FriendsScreen(),
              ));
            },
            iconData: Icons.person_add_outlined,
            iconSize: 24,
            tooltip: 'Search',
          ),
          CustomIconButton(
            onPressed: () {},
            iconData: Icons.message,
            iconSize: 24,
            tooltip: 'Message',
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            PostsScreen(),
            ReelsScreen(),
            const Center(child: Text('Market')),
            MenuScreen(authService: widget.authService),
          ],
        ),
      ),
    );
  }
}
