import 'package:facebook_clone/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../services/friend_services/friend_service.dart';

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
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          children: [
            CustomIconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                iconData: Icons.arrow_back_ios),
            const Text('Friends'),
          ],
        ),
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
        Expanded(child: _buildTabs()),
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
          Expanded(
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent')),
        );
      }
    } catch (e) {
      setState(() {
        _requestStatus.remove(receiverId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request canceled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel request: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(String senderId) async {
    try {
      // Find the request to accept.
      // This assumes that getFriendRequests returns all requests involving the current user.
      final requests = await _friendService.getFriendRequests(user!.id);
      final requestToAccept = requests.firstWhere(
        (req) => req.senderId == senderId && req.receiverId == user!.id,
        // orElse: () => null, // Depending on your FriendRequestModel structure and null safety
      );

      await _friendService.acceptFriendRequest(
        requestId: requestToAccept.id,
        receiverId: user!.id,
      );

      setState(() {
        _requestStatus[senderId] = FriendRequestStatus.friends;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
      }
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String senderId) async {
    // Add senderId parameter
    try {
      // Find the request to reject.
      final requests = await _friendService.getFriendRequests(user!.id);
      final requestToReject = requests.firstWhere(
        (req) => req.senderId == senderId && req.receiverId == user!.id,
        // orElse: () => null, // Depending on your FriendRequestModel structure and null safety
      );

      await _friendService.rejectFriendRequest(
        requestId: requestToReject.id,
        receiverId: user!.id,
      );

      setState(() {
        // Remove the status or set to none, depending on desired behavior after rejection
        _requestStatus.remove(senderId);
        // OR
        // _requestStatus[senderId] = FriendRequestStatus.none;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request rejected')),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject request: $e')),
        );
      }
    }
  }

  Widget _buildSuggestionsTab() {
    final suggestions = _users.where((user) {
      final status = _requestStatus[user['id']];
      return status == null || status == FriendRequestStatus.none;
    }).toList();

    return _buildUserList(suggestions, 'No users suggestions', '');
  }

  Widget _buildSentRequestsTab() {
    final sentRequests = _users.where((user) {
      return _requestStatus[user['id']] == FriendRequestStatus.sent;
    }).toList();

    return _buildUserList(sentRequests, 'You don\'t send any request', '');
  }

  Widget _buildReceivedRequestsTab() {
    final receivedRequests = _users.where((user) {
      return _requestStatus[user['id']] == FriendRequestStatus.received;
    }).toList();

    return _buildUserList(
        receivedRequests, 'There is no received friend request', '');
  }

  Widget _buildUserList(
    List<Map<String, dynamic>> users,
    String firstText,
    String? secoundText,
  ) {
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
            const SizedBox(height: 8),
            Text(
              secoundText ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
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
