import 'package:facebook_clone/features/layout/viewmodel/layout_cubit.dart';
import 'package:facebook_clone/features/layout/viewmodel/layout_state.dart';
import 'package:facebook_clone/features/menu/view/menu_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/custom_icon_button.dart';
import '../../../core/widgets/custom_text.dart';
import '../../../screens/friends/friends_screen.dart';
import '../../../screens/posts/posts_screen.dart';
import '../../../screens/reels/reels_screen.dart';

class LayoutView extends StatelessWidget {
  const LayoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: BlocBuilder<LayoutCubit, LayoutState>(
        builder: (context, state) {
          return Scaffold(
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
                  Tab(icon: Icon(Icons.home_outlined, size: 32)),
                  Tab(icon: Icon(Icons.ondemand_video_outlined, size: 32)),
                  Tab(icon: Icon(Icons.storefront_outlined, size: 32)),
                  Tab(icon: Icon(Icons.menu_outlined, size: 32)),
                ],
                indicatorSize: TabBarIndicatorSize.tab,
                enableFeedback: null,
                tabAlignment: null,
                indicatorAnimation: TabIndicatorAnimation.elastic,
              ),
              actions: [
                CustomIconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FriendsScreen(),
                      ),
                    );
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
                children: [
                  if (state.status == LayoutStatus.userSuccess &&
                      state.data != null)
                    PostsScreen(
                      user: state.data!,
                    ),
                  ReelsScreen(),
                  const Center(child: Text('Market')),
                  // ✅ Handle state
                  if (state.status == LayoutStatus.userSuccess &&
                      state.data != null)
                    MenuView(currentUser: state.data!)
                  else
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
