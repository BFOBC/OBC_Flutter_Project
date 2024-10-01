import 'package:flutter/material.dart';

class ConfirmLocationChangeDialog extends StatelessWidget {
  final Function onConfirm; // Function to call when "Yes" is pressed

  const ConfirmLocationChangeDialog({Key? key, required this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Change Base Location"),
      content: const Text("Do you want to change your base location?"),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog on "No"
          },
          child: const Text("No"),
        ),
        TextButton(
          onPressed: () {
            onConfirm();  // Call the function when "Yes" is pressed
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text("Yes"),
        ),
      ],
    );
  }
}
