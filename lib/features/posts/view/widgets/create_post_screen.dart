import 'dart:io';

import 'package:facebook_clone/core/services/post_services/post_service.dart';
import 'package:facebook_clone/core/utlis/image_picker_utils.dart';
import 'package:facebook_clone/core/widgets/custom_button.dart';
import 'package:facebook_clone/core/widgets/custom_icon_button.dart';
import 'package:facebook_clone/core/widgets/custom_text.dart';
import 'package:facebook_clone/core/widgets/custom_text_field.dart';
import 'package:facebook_clone/core/widgets/video_preview.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/consts/theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _postController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  File? _selectedImage;
  File? _selectedVideo;
  final user = supabase.Supabase.instance.client.auth.currentUser;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final File? imageFile = await ImagePickerUtils.pickImageFromGallery();
      if (imageFile == null) return;

      setState(() {
        _selectedImage = imageFile;
        _errorMessage = null;
      });
    } catch (e) {
      _setError('Failed to pick image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final File? videoFile = await ImagePickerUtils.pickVideoFromGallery();
      if (videoFile == null) return;

      setState(() {
        _selectedVideo = videoFile;
        _errorMessage = null;
      });
    } catch (e) {
      _setError('Failed to pick image: $e');
    }
  }

  Future<void> _createPost() async {
    if (!_validatePost()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (user == null) {
        throw Exception('User not logged in');
      }

      final postService = PostService();

      await postService.createPost(
        postText: _postController.text.trim(),
        user: user!,
        imageFile: _selectedImage,
        videoFile: _selectedVideo,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _setError('Failed to create post: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validatePost() {
    if (_postController.text.trim().isEmpty && _selectedImage == null) {
      _setError('Please add some text or an image to your post');
      return false;
    }
    return true;
  }

  void _setError(String message) {
    if (mounted) {
      setState(() => _errorMessage = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 70,
        leading: CustomIconButton(
          onPressed: () => Navigator.pop(context, _isLoading),
          iconData: Icons.arrow_back_ios,
        ),
        title: const CustomText('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildPostButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPostInput(),
                if (_selectedImage != null) _buildImagePreview(),
                if (_selectedVideo != null)
                  SizedBox(
                      height: 300,
                      child: VideoPreview(videoUrl: _selectedVideo!.path)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPickPhotoButton(),
                    SizedBox(
                      width: 20,
                    ),
                    _buildPickVideoButton(),
                  ],
                ),
                if (_errorMessage != null) _buildErrorMessage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 25,
        ),
      ),
      onPressed: _createPost,
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            )
          : const Text(
              'POST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildPostInput() {
    return CustomTextField(
      decoration: const InputDecoration(
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
        border: OutlineInputBorder(borderSide: BorderSide.none),
        disabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
      ),
      controller: _postController,
      hintText: "What's on your mind?",
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      },
    );
  }

  Widget _buildImagePreview() {
    final double screenHight = MediaQuery.of(context).size.height;
    final double estimatedHeight = (screenHight * 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              height: estimatedHeight,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickPhotoButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          onPressed: _pickImage,
          text: 'Add Photo',
          icon: const Icon(Icons.photo_library),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            foregroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.primary,
            ),
            side: WidgetStateProperty.all(
              BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            minimumSize: WidgetStateProperty.all(const Size(120, 40)),
          ),
        ),
      ],
    );
  }

  Widget _buildPickVideoButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          onPressed: () async {
            await _pickVideo();
            debugPrint(_selectedVideo.toString());
          },
          text: 'Add Video',
          icon: const Icon(Icons.video_camera_back),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            foregroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.primary,
            ),
            side: WidgetStateProperty.all(
              BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            minimumSize: WidgetStateProperty.all(const Size(120, 40)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Card(
          color: Colors.red.withAlpha(150),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomText(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => setState(() => _errorMessage = null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
