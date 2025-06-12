import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer loading placeholder widget that mimics the structure of a post item.
/// This widget is used to show a loading state while the actual post content is being fetched.
class PostShimmerItem extends StatelessWidget {
  const PostShimmerItem({super.key});

  // Constants for shimmer colors
  static const Color _baseColor = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color _highlightColor = Color(0xFFF5F5F5); // Colors.grey[100]

  // Constants for dimensions
  static const double _avatarRadius = 27.0;
  static const double _spacingSmall = 4.0;
  static const double _spacingMedium = 8.0;
  static const double _spacingLarge = 10.0;
  static const double _spacingExtraLarge = 15.0;
  static const double _horizontalPadding = 10.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final estimatedImageHeight = screenWidth * (9 / 16);

    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserSection(),
          const SizedBox(height: _spacingLarge),
          _buildPostTextSection(screenWidth),
          const SizedBox(height: _spacingLarge),
          _buildPostImageSection(estimatedImageHeight),
          const SizedBox(height: _spacingLarge),
          _buildStatsSection(),
          const SizedBox(height: _spacingExtraLarge),
          _buildActionsSection(),
        ],
      ),
    );
  }

  /// Builds the user section with avatar and name placeholders.
  /// Includes a circular avatar and two text lines for name and timestamp.
  Widget _buildUserSection() {
    return Row(
      children: [
        CircleAvatar(radius: _avatarRadius),
        const SizedBox(width: _spacingMedium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 16, color: Colors.white),
            const SizedBox(height: _spacingSmall),
            Container(width: 80, height: 12, color: Colors.white),
          ],
        ),
      ],
    );
  }

  /// Builds the post text section with placeholder lines.
  /// Creates two lines of text with different widths to simulate post content.
  Widget _buildPostTextSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: double.infinity, height: 14, color: Colors.white),
        const SizedBox(height: _spacingSmall),
        Container(width: screenWidth * 0.7, height: 14, color: Colors.white),
      ],
    );
  }

  /// Builds the post image placeholder.
  /// Creates a container with aspect ratio 16:9 to simulate a post image.
  Widget _buildPostImageSection(double height) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.white,
    );
  }

  /// Builds the stats section showing reactions, comments, and shares.
  /// Creates three placeholder containers for different stats.
  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(width: 60, height: 12, color: Colors.white),
        Container(width: 80, height: 12, color: Colors.white),
        Container(width: 70, height: 12, color: Colors.white),
      ],
    );
  }

  /// Builds the actions section with placeholders for like, comment, and share buttons.
  /// Creates three action buttons with icons and labels.
  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (_) => _buildActionPlaceholder()),
      ),
    );
  }

  /// Builds a single action placeholder with icon and text.
  /// Creates a row with an icon container and a text container.
  Widget _buildActionPlaceholder() {
    return Row(
      children: [
        Container(width: 24, height: 24, color: Colors.white),
        const SizedBox(width: 5),
        Container(width: 50, height: 12, color: Colors.white),
      ],
    );
  }
}
