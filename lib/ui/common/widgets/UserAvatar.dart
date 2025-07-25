import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const UserAvatar({
    Key? key,
    required this.imageUrl,
    this.size = 60,
  }) : super(key: key);

  bool _isValidUrl(String? url) {
    return url != null && url.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _isValidUrl(imageUrl);

    return GestureDetector(
      onTap: () {
        if (hasImage) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    Navigator.pop(context); // Close dialog if error
                    return const SizedBox(); // No preview
                  },
                ),
              ),
            ),
          );
        }
      },
      child: Container(
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
      ),
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
