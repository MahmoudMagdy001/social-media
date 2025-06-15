import 'package:facebook_clone/services/freind_services/freind_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final user = supabase.Supabase.instance.client.auth.currentUser;
  final FriendService _friendService = FriendService();

  List<Map<String, dynamic>> _users = [];
  Map<String, FriendRequestStatus> _requestStatus = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load all users except current user
      final users = await _friendService.getAllUsersExceptCurrent();

      // Load all friend requests involving current user
      final requests = await _friendService.getFriendRequests(user!.id);

      // Create status map
      final statusMap = <String, FriendRequestStatus>{};

      for (var request in requests) {
        if (request.senderId == user!.id) {
          // Current user is the sender
          statusMap[request.receiverId] = FriendRequestStatus.sent;
        } else if (request.receiverId == user!.id) {
          // Current user is the receiver
          statusMap[request.senderId] = FriendRequestStatus.received;
        }
      }

      // Check friendships
      final friends = await _friendService.getFriends(user!.id);
      for (var friend in friends) {
        final friendId = friend['id'];
        statusMap[friendId] = FriendRequestStatus.friends;
      }

      setState(() {
        _users = users;
        _requestStatus = statusMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTabs(),
      ],
    );
  }

  Widget _buildTabs() {
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
          SizedBox(
            height: 200, // Adjust height as needed
            child: TabBarView(
              children: [
                _buildSuggestionsTab(),
                _buildSentRequestsTab(),
                _buildReceivedRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final userId = user['id'];
    final status = _requestStatus[userId] ?? FriendRequestStatus.none;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user['profile_image'] ?? ''),
      ),
      title: Text(user['display_name'] ?? 'No name'),
      subtitle: Text(user['email'] ?? ''),
      trailing: _buildActionButton(userId, status),
    );
  }

  Widget _buildActionButton(String userId, FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.sent:
        return OutlinedButton(
          onPressed: () => _cancelRequest(userId),
          child: const Text('Cancel'),
        );
      case FriendRequestStatus.received:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _acceptRequest(userId),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _rejectRequest(userId),
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
          onPressed: () => _sendFriendRequest(userId),
          child: const Text('Add Friend'),
        );
    }
  }

  Future<void> _sendFriendRequest(String receiverId) async {
    try {
      setState(() {
        _requestStatus[receiverId] = FriendRequestStatus.sent;
      });

      await _friendService.sendFriendRequest(
        senderId: user!.id,
        receiverId: receiverId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
    } catch (e) {
      setState(() {
        _requestStatus.remove(receiverId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  Future<void> _cancelRequest(String userId) async {
    try {
      await _friendService.cancelFriendRequest(
        senderId: user!.id,
        receiverId: userId,
      );

      setState(() {
        _requestStatus.remove(userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request canceled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel request: $e')),
      );
    }
  }

  Future<void> _acceptRequest(String senderId) async {
    try {
      await _friendService.acceptFriendRequest(
        requestId: _getRequestId(senderId, user!.id)!,
        receiverId: user!.id,
      );

      setState(() {
        _requestStatus[senderId] = FriendRequestStatus.friends;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request: $e')),
      );
    }
  }

  Future<void> _rejectRequest(String senderId) async {
    try {
      await _friendService.rejectFriendRequest(
        requestId: _getRequestId(senderId, user!.id)!,
        receiverId: user!.id,
      );

      setState(() {
        _requestStatus.remove(senderId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request: $e')),
      );
    }
  }

  String? _getRequestId(String senderId, String receiverId) {
    // You'll need to implement this based on how you track requests
    // This should return the request ID for the given sender-receiver pair
    return null;
  }

  Widget _buildSuggestionsTab() {
    final suggestions = _users.where((user) {
      final status = _requestStatus[user['id']];
      return status == null || status == FriendRequestStatus.none;
    }).toList();

    return _buildUserList(suggestions);
  }

  Widget _buildSentRequestsTab() {
    final sentRequests = _users.where((user) {
      return _requestStatus[user['id']] == FriendRequestStatus.sent;
    }).toList();

    return _buildUserList(sentRequests);
  }

  Widget _buildReceivedRequestsTab() {
    final receivedRequests = _users.where((user) {
      return _requestStatus[user['id']] == FriendRequestStatus.received;
    }).toList();

    return _buildUserList(receivedRequests);
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildUserItem(users[index]);
      },
    );
  }
}

enum FriendRequestStatus {
  none,
  sent,
  received,
  friends,
}
