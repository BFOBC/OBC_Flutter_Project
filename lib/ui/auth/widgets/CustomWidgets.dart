// Helper function to create header buttons with equal width
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../res/custom_colors.dart';

import 'package:flutter/material.dart';

class HeaderButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const HeaderButton({
    Key? key,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130, // Fixed width for equal size buttons
      height: 40, // Fixed height for consistency
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.primaryColor, // Set the desired color or pass as parameter
          foregroundColor: Colors.white, // Set the text color of the button
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18, // Adjust the font size as per your need
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

