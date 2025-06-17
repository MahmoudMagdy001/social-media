import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ItemShimmer extends StatelessWidget {
  const ItemShimmer({super.key});

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

  Widget _buildPostImageSection(double height) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.white,
    );
  }

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

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (_) => _buildActionPlaceholder()),
      ),
    );
  }

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

class ListShimmer extends StatelessWidget {
  const ListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) => Column(
        children: [
          const SizedBox(height: 10),
          Divider(
            color: Theme.of(context).dividerColor.withAlpha(50),
          ),
          const SizedBox(height: 5),
        ],
      ),
      itemCount: 5,
      itemBuilder: (_, __) => const ItemShimmer(),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 20,
                    width: 150,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(height: 16, width: 30, color: Colors.white),
                      const SizedBox(width: 5),
                      Container(height: 16, width: 60, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: Column(
                          children: [
                            const CircleAvatar(
                                radius: 28, backgroundColor: Colors.white),
                            const SizedBox(height: 5),
                            Container(
                                width: 60, height: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, __) => const ItemShimmer(),
            ),
          ],
        ),
      ),
    );
  }
}
