import 'package:facebook_clone/widgets/custom_icon_button.dart';
import 'package:facebook_clone/widgets/custom_text.dart';
import 'package:flutter/material.dart';

class LikesScreen extends StatefulWidget {
  final Stream<List<Map<String, dynamic>>> likesStream;

  const LikesScreen({super.key, required this.likesStream});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          children: [
            CustomIconButton(
              onPressed: () => Navigator.of(context).pop(),
              iconData: Icons.arrow_back_ios_new,
            ),
            const SizedBox(width: 10),
            const CustomText(
              'Likes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.likesStream,
        builder: (context, snapshot) {
          // Display a loading indicator while waiting for data.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Show error message if an error occurs.
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final likes = snapshot.data ?? [];

          if (likes.isEmpty) {
            return const Center(child: Text('No likes yet'));
          }

          return ListView.builder(
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final user = likes[index];
              return ListTile(
                leading: Icon(Icons.thumb_up_alt_rounded, color: Colors.blue),
                title: Text(user['display_name'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
