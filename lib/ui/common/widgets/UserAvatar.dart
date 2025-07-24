import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const UserAvatar({
    Key? key,
    required this.imageUrl,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildCenteredIcon();
        },
      )
          : _buildCenteredIcon(),
    );
  }

  Widget _buildCenteredIcon() {
    return Center(
      child: Image.asset(
        'assets/place_holder_man.png',
        width: size * 0.5,
        height: size * 0.5,
        fit: BoxFit.contain,
      ),
    );
  }
}

