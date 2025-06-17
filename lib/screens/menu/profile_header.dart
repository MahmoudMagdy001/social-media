import 'package:facebook_clone/screens/friends/friend_list.dart';
import 'package:facebook_clone/services/friend_services/friend_service.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String profileImage;
  final String displayName;
  final List<Map<String, dynamic>> friendsList;
  final FriendService friendService;
  final String? friendsError;
  final bool isOwner;

  const ProfileHeader({
    super.key,
    required this.profileImage,
    required this.displayName,
    required this.friendsList,
    required this.friendService,
    this.friendsError,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final friendsCount = friendsList.length;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: NetworkImage(profileImage),
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(height: 10),
          CustomText(
            displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Divider(),
          Row(
            children: [
              CustomText(
                friendsCount.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              CustomText(friendsCount == 1 ? 'Friend' : 'Friends'),
              const Spacer(),
              if (friendsError == null)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return FriendsList(
                            friendsList: friendsList,
                            friendService: friendService,
                            isOwner: isOwner,
                          );
                        },
                      ),
                    );
                  },
                  child: CustomText(
                    'show all friends',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
            ],
          ),
          if (friendsError != null) ...[
            const SizedBox(height: 5),
            CustomText(friendsError!,
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          if (friendsList.isNotEmpty)
            SizedBox(
              height: friendsCount == 1 ? 142 : 330,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friendsList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: friendsCount == 1 ? 1 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final friend = friendsList[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: NetworkImage(friend['profile_image'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 100,
                        child: Text(
                          friend['display_name'] ?? 'N/A',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
