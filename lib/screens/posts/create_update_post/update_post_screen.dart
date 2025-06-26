import 'dart:io';

import 'package:facebook_clone/models/post_data_model.dart';
import 'package:facebook_clone/services/post_services/post_service.dart';
import 'package:facebook_clone/core/utlis/image_picker_utils.dart';
import 'package:facebook_clone/core/widgets/custom_button.dart';
import 'package:facebook_clone/core/widgets/custom_icon_button.dart';
import 'package:facebook_clone/core/widgets/custom_text.dart';
import 'package:facebook_clone/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:facebook_clone/core/consts/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Screen for updating an existing post
class UpdatePostScreen extends StatefulWidget {
  final PostDataModel post;

  const UpdatePostScreen({super.key, required this.post});

  @override
  State<UpdatePostScreen> createState() => _UpdatePostScreenState();
}

class _UpdatePostScreenState extends State<UpdatePostScreen> {
  static const double _padding = 16.0;
  static const double _imageAspectRatio = 1.1;
  static const double _iconSize = 50.0;
  static const double _borderRadius = 12.0;

  final TextEditingController _textController = TextEditingController();
  final PostService _postService = PostService();
  final user = supabase.Supabase.instance.client.auth.currentUser;

  String? _imageUrl;
  File? _newImage;
  bool _removeImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePostData();
  }

  void _initializePostData() {
    _textController.text = widget.post.postText;
    _imageUrl = widget.post.postImageUrl ?? '';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final File? imageFile = await ImagePickerUtils.pickImageFromGallery();
      if (imageFile != null) {
        setState(() {
          _newImage = imageFile;
          _removeImage = false; // Reset removeImage when new image is picked
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePost() async {
    if (!_validatePost()) return;

    setState(() => _isLoading = true);

    try {
      if (user == null) throw Exception('User not authenticated');

      await _postService.updatePost(
        postId: widget.post.documentId,
        userId: user!.id,
        updatedText: _textController.text.trim(),
        newImageFile: _newImage,
        removeImage: _removeImage,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      _showSuccessMessage();
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validatePost() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasImage =
        _newImage != null || (_imageUrl != null && _imageUrl!.isNotEmpty);
    final isRemovingImageOnly = _removeImage && hasText;

    if (!hasText && !hasImage && !isRemovingImageOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enter text or select an image to update the post.')),
      );
      return false;
    }
    return true;
  }

  void _showSuccessMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Post updated successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to update post: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 70,
        leading: CustomIconButton(
          onPressed: () => Navigator.of(context).pop(),
          iconData: Icons.arrow_back_ios,
        ),
        title: const CustomText('Update Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildUpdateButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              _buildPostInput(),
              const SizedBox(height: _padding),
              if (_shouldShowImage()) _buildPostImage(),
              const SizedBox(height: _padding),
              _buildAddPhotoButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 25,
        ),
      ),
      onPressed: _updatePost,
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
              'UPDATE',
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
      controller: _textController,
      hintText: "What's on your mind?",
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter some text' : null,
    );
  }

  Widget _buildPostImage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final estimatedImageHeight = screenWidth * _imageAspectRatio;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Image(
            image: _newImage != null
                ? FileImage(_newImage!)
                : NetworkImage(_imageUrl ?? '') as ImageProvider,
            width: double.infinity,
            fit: BoxFit.cover,
            height: estimatedImageHeight,
            errorBuilder: (context, error, stackTrace) => _buildErrorImage(
              estimatedImageHeight,
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: estimatedImageHeight,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() {
              _imageUrl = null;
              _newImage = null;
              _removeImage = true; // Mark for removal
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorImage(double height) {
    return Container(
      width: double.infinity,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.error_outline,
        size: _iconSize,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 100.0),
      child: CustomButton(
        onPressed: _pickImage,
        text: 'Add Photo',
        icon: const Icon(Icons.photo_library),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor:
              WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          side: WidgetStateProperty.all(
            BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          minimumSize: WidgetStateProperty.all(const Size(120, 40)),
        ),
      ),
    );
  }

  bool _shouldShowImage() {
    return (_imageUrl != null || _newImage != null) &&
        (_imageUrl != '' || _newImage != null);
  }
}
