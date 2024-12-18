import 'package:flutter/material.dart';

class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Exit App"),
      content: Text("Are you sure you want to exit the app?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Stay in app
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true), // Exit app
          child: Text("Exit"),
        ),
      ],
    );
  }
}
