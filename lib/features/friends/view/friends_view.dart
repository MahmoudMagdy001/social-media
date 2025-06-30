import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/features/friends/viewmodel/friends_cubit.dart';
import 'package:facebook_clone/core/services/friend_services/friend_service.dart';
import 'package:facebook_clone/core/widgets/custom_icon_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return BlocProvider(
      create: (_) =>
          FriendsCubit(friendService: FriendService(), userId: user!.id)
            ..fetchFriendsData(),
      child: BlocBuilder<FriendsCubit, FriendsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              centerTitle: false,
              title: Row(
                children: [
                  CustomIconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    iconData: Icons.arrow_back_ios,
                  ),
                  const Text('Friends'),
                ],
              ),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, FriendsState state) {
    if (state is FriendsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is FriendsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.message}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<FriendsCubit>().fetchFriendsData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state is FriendsLoaded) {
      return Column(
        children: [
          Expanded(child: _buildTabs(context, state)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTabs(BuildContext context, FriendsLoaded state) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Suggestions'),
              Tab(text: 'Sent Requests'),
              Tab(text: 'Received'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUserList(context, state, FriendRequestStatus.none,
                    'No users suggestions', ''),
                _buildUserList(context, state, FriendRequestStatus.sent,
                    'You don\'t send any request', ''),
                _buildUserList(context, state, FriendRequestStatus.received,
                    'There is no received friend request', ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context, FriendsLoaded state,
      FriendRequestStatus filter, String firstText, String? secondText) {
    final users = state.users.where((user) {
      final status = state.requestStatus[user['id']];
      if (filter == FriendRequestStatus.none) {
        return status == null || status == FriendRequestStatus.none;
      }
      return status == filter;
    }).toList();
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              firstText,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            if ((secondText ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                secondText!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildUserItem(context, users[index], state.requestStatus);
      },
    );
  }

  Widget _buildUserItem(BuildContext context, Map<String, dynamic> user,
      Map<String, FriendRequestStatus> requestStatus) {
    final userId = user['id'];
    final status = requestStatus[userId] ?? FriendRequestStatus.none;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user['profile_image'] ?? ''),
      ),
      title: Text(user['display_name'] ?? 'No name'),
      subtitle: Text(user['email'] ?? ''),
      trailing: _buildActionButton(context, userId, status),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String userId, FriendRequestStatus status) {
    final cubit = context.read<FriendsCubit>();
    switch (status) {
      case FriendRequestStatus.sent:
        return OutlinedButton(
          onPressed: () => cubit.cancelRequest(userId),
          child: const Text('Cancel'),
        );
      case FriendRequestStatus.received:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => cubit.acceptRequest(userId),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => cubit.rejectRequest(userId),
              child: const Text('Reject'),
            ),
          ],
        );
      case FriendRequestStatus.friends:
        return const Chip(
          label: Text('Friends'),
          backgroundColor: Colors.blue,
          labelStyle: TextStyle(color: Colors.white),
        );
      case FriendRequestStatus.none:
        return ElevatedButton(
          onPressed: () => cubit.sendRequest(userId),
          child: const Text('Add Friend'),
        );
    }
  }
}
