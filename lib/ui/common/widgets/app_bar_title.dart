import 'package:flutter/material.dart';

import '../../../../res/custom_colors.dart';


class AppBarTitle extends StatelessWidget {
  final String sectionName;

  const AppBarTitle({
    super.key,
    required this.sectionName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/firebase_logo.png',
          height: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'FlutterFire',
          style: TextStyle(
            color: Palette.firebaseYellow,
            fontSize: 18,
          ),
        ),
        Text(
          ' $sectionName',
          style: const TextStyle(
            color: Palette.firebaseOrange,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
