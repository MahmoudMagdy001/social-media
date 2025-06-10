// import 'dart:io';

// import 'package:facebook_clone/models/post_data_model.dart';
// import 'package:facebook_clone/services/auth_services/auth_service.dart';
// import 'package:facebook_clone/services/post_services/post_service.dart';
// import 'package:facebook_clone/utils/image_picker_utils.dart';
// import 'package:facebook_clone/widgets/custom_button.dart';
// import 'package:facebook_clone/widgets/custom_icon_button.dart';
// import 'package:facebook_clone/widgets/custom_text.dart';
// import 'package:facebook_clone/widgets/custom_text_field.dart';
// import 'package:flutter/material.dart';
// import 'package:facebook_clone/consts/theme.dart';
// import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// /// Screen for updating an existing post
// class UpdatePostScreen extends StatefulWidget {
//   final PostDataModel post;

//   const UpdatePostScreen({super.key, required this.post});

//   @override
//   State<UpdatePostScreen> createState() => _UpdatePostScreenState();
// }

// class _UpdatePostScreenState extends State<UpdatePostScreen> {
//   static const double _padding = 16.0;
//   static const double _imageAspectRatio = 1.1;
//   static const double _iconSize = 50.0;
//   static const double _borderRadius = 12.0;

//   final TextEditingController _textController = TextEditingController();
//   final PostService _postService = PostService();

//   String? _imageUrl;
//   File? _newImage;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializePostData();
//   }

//   void _initializePostData() {
//     _textController.text = widget.post.postText;
//     // Note: PostDataModel doesn't have postImageUrl field
//     // We'll handle images in a future update
//   }

//   @override
//   void dispose() {
//     _textController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     try {
//       final File? imageFile = await ImagePickerUtils.pickImageFromGallery();
//       if (imageFile != null) {
//         setState(() => _newImage = imageFile);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error picking image: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _updatePost() async {
//     if (!_validatePost()) return;

//     setState(() => _isLoading = true);

//     try {
//       final user = await supabase.User;
//       if (user == null) throw Exception('User not authenticated');

//       await _postService.updatePost(
//         postId: widget.post.documentId,
//         userId: user.,
//         postText: _textController.text.trim(),
//       );

//       if (!mounted) return;

//       Navigator.pop(context, true);
//       _showSuccessMessage();
//     } catch (e) {
//       if (!mounted) return;
//       _showErrorMessage(e.toString());
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   bool _validatePost() {
//     if (_textController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Post text cannot be empty')),
//       );
//       return false;
//     }
//     return true;
//   }

//   void _showSuccessMessage() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Post updated successfully')),
//     );
//   }

//   void _showErrorMessage(String error) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Failed to update post: $error'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: false,
//         toolbarHeight: 70,
//         leading: CustomIconButton(
//           onPressed: () => Navigator.of(context).pop(),
//           iconData: Icons.arrow_back_ios,
//         ),
//         title: const CustomText('Update Post'),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 8.0),
//             child: _buildUpdateButton(),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 5),
//               _buildPostInput(),
//               const SizedBox(height: _padding),
//               if (_shouldShowImage()) _buildPostImage(),
//               const SizedBox(height: _padding),
//               _buildAddPhotoButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildUpdateButton() {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: AppTheme.lightTheme.colorScheme.primary,
//         padding: const EdgeInsets.symmetric(
//           vertical: 10,
//           horizontal: 25,
//         ),
//       ),
//       onPressed: _updatePost,
//       child: _isLoading
//           ? SizedBox(
//               height: 20,
//               width: 20,
//               child: Center(
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 3,
//                 ),
//               ),
//             )
//           : const Text(
//               'UPDATE',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//     );
//   }

//   Widget _buildPostInput() {
//     return CustomTextField(
//       decoration: const InputDecoration(
//         fillColor: Colors.transparent,
//         enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
//         border: OutlineInputBorder(borderSide: BorderSide.none),
//         disabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
//         focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
//       ),
//       controller: _textController,
//       hintText: "What's on your mind?",
//       validator: (value) =>
//           value?.isEmpty ?? true ? 'Please enter some text' : null,
//     );
//   }

//   Widget _buildPostImage() {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final estimatedImageHeight = screenWidth * _imageAspectRatio;

//     return Stack(
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(_borderRadius),
//           child: Image(
//             image: _newImage != null
//                 ? FileImage(_newImage!)
//                 : NetworkImage(_imageUrl ?? '') as ImageProvider,
//             width: double.infinity,
//             fit: BoxFit.cover,
//             height: estimatedImageHeight,
//             errorBuilder: (context, error, stackTrace) => _buildErrorImage(
//               estimatedImageHeight,
//             ),
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return Container(
//                 width: double.infinity,
//                 height: estimatedImageHeight,
//                 color: Theme.of(context).colorScheme.surfaceContainerHighest,
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                             loadingProgress.expectedTotalBytes!
//                         : null,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         Positioned(
//           top: 8,
//           right: 8,
//           child: IconButton(
//             icon: const Icon(Icons.close, color: Colors.white),
//             onPressed: () => setState(() {
//               _imageUrl = null;
//               _newImage = null;
//             }),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorImage(double height) {
//     return Container(
//       width: double.infinity,
//       height: height,
//       color: Theme.of(context).colorScheme.surfaceContainerHighest,
//       child: Icon(
//         Icons.error_outline,
//         size: _iconSize,
//         color: Theme.of(context).colorScheme.error,
//       ),
//     );
//   }

//   Widget _buildAddPhotoButton() {
//     return Container(
//       alignment: Alignment.centerLeft,
//       padding: const EdgeInsets.symmetric(horizontal: 100.0),
//       child: CustomButton(
//         onPressed: _pickImage,
//         text: 'Add Photo',
//         icon: const Icon(Icons.photo_library),
//         style: ButtonStyle(
//           backgroundColor: WidgetStateProperty.all(Colors.transparent),
//           foregroundColor:
//               WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
//           side: WidgetStateProperty.all(
//             BorderSide(color: Theme.of(context).colorScheme.primary),
//           ),
//           minimumSize: WidgetStateProperty.all(const Size(120, 40)),
//         ),
//       ),
//     );
//   }

//   bool _shouldShowImage() {
//     return (_imageUrl != null || _newImage != null) &&
//         (_imageUrl != '' || _newImage != null);
//   }
// }
