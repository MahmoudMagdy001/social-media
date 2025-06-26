import 'dart:io';

import 'package:flutter/material.dart';

import '../../viewmodel/signup_cubit.dart';

class UserImage extends StatelessWidget {
  const UserImage({
    super.key,
    required this.cubit,
    required this.isImageLoading,
    required this.profileImage,
  });

  final SignupCubit cubit;
  final bool isImageLoading;
  final File? profileImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => cubit.pickProfileImage(context),
        child: CircleAvatar(
          radius: 80,
          backgroundColor: Colors.grey[200],
          child: isImageLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : profileImage != null
                  ? ClipOval(
                      child: Image.file(
                        profileImage!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 40, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
