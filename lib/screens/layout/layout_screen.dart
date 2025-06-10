import 'package:facebook_clone/screens/menu/menu_screen.dart';
import 'package:facebook_clone/widgets/custom_icon_button.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:flutter/material.dart';

import '../../services/auth_services/auth_service.dart';
import '../posts/posts_screen.dart';

class LayoutScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final AuthService authService;
  const LayoutScreen({
    super.key,
    required this.userData,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: CustomText(
            'Social Media',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          bottom: const TabBar(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 4.0, color: Colors.blue),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            tabs: [
              Tab(icon: Icon(Icons.home, size: 32)),
              Tab(icon: Icon(Icons.ondemand_video, size: 32)),
              Tab(icon: Icon(Icons.storefront_outlined, size: 32)),
              Tab(icon: Icon(Icons.menu, size: 32)),
            ],
            indicatorSize: TabBarIndicatorSize.tab,
            enableFeedback: null,
            tabAlignment: null,
            indicatorAnimation: TabIndicatorAnimation.elastic,
          ),
          actions: [
            CustomIconButton(
              onPressed: () {},
              iconData: Icons.search,
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
            children: [
              PostsScreen(authService: authService),
              const Center(child: Text('Watch')),
              const Center(child: Text('Market')),
              MenuScreen(authService: authService),
            ],
          ),
        ),
      ),
    );
  }
}
