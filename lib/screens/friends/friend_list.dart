import 'package:facebook_clone/services/friend_services/friend_service.dart';
import 'package:facebook_clone/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../widgets/custom_icon_button.dart';

class FriendsList extends StatefulWidget {
  final List<Map<String, dynamic>> friendsList;
  final FriendService friendService;
  final bool isOwner;

  const FriendsList({
    super.key,
    required this.friendsList,
    required this.friendService,
    required this.isOwner,
  });

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  late final String? currentUserId;

  @override
  void initState() {
    super.initState();

    currentUserId = supabase.Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      debugPrint(
          "Error: Current user ID is null. User might not be logged in.");
    }
  }

  Future<void> _deleteFriend(
      BuildContext context, Map<String, dynamic> friend) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: User not identified. Please try again.')),
      );
      return;
    }

    if (friend['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Friend ID is missing.')),
      );
      return;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: Text('Delete Friend'),
              content: isDeleting
                  ? Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text("Deleting..."),
                        ],
                      ),
                    )
                  : Text(
                      'Are you sure you want to remove ${friend['display_name'] ?? 'this user'} from your friends?',
                    ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                          Navigator.of(dialogContext)
                              .pop(false); // Not confirmed
                        },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          stfSetState(() {
                            isDeleting = true;
                          });
                          try {
                            await widget.friendService.deleteFriend(
                              userId:
                                  currentUserId!, // We checked for null above
                              friendId: friend['id'],
                            );
                            debugPrint('Friend deleted successfully!');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${friend['display_name'] ?? 'Friend'} removed successfully!')),
                              );
                              setState(() {
                                widget.friendsList.removeWhere(
                                    (f) => f['id'] == friend['id']);
                              });
                            }
                            if (context.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } catch (e) {
                            debugPrint('Error deleting friend: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error deleting friend: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                            if (context.mounted) {
                              Navigator.of(dialogContext).pop(false);
                            }
                          }
                        },
                  child: Text(
                    'Delete',
                    style:
                        TextStyle(color: isDeleting ? Colors.grey : Colors.red),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friends List')),
        body: const Center(
          child: Text('User not logged in. Cannot display friends.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CustomIconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              iconData: Icons.arrow_back_ios,
            ),
            const Text('Friends List'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              if (widget.friendsList.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.friendsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final friend = widget.friendsList[index];
                      // Use a placeholder if image URL is null or empty
                      final String? profileImageUrl =
                          friend['profile_image'] as String?;

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: (profileImageUrl != null &&
                                    profileImageUrl.isNotEmpty)
                                ? NetworkImage(profileImageUrl)
                                : null,
                            // Use null to show background color or child
                            child: (profileImageUrl == null ||
                                    profileImageUrl.isEmpty)
                                ? Icon(Icons.person,
                                    size: 35,
                                    color: Colors.grey[600]) // Placeholder icon
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            // Use Expanded to prevent overflow for long names/emails
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend['display_name'] ?? 'No Name',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  friend['email'] ?? 'No Email',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          widget.isOwner
                              ? CustomButton(
                                  onPressed: () {
                                    _deleteFriend(context, friend);
                                  },
                                  text: 'Delete',
                                )
                              : SizedBox.shrink()
                        ],
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60, color: Colors.grey[500]),
                        const SizedBox(height: 16),
                        Text(
                          'You have no friends yet.',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start connecting with others!',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
