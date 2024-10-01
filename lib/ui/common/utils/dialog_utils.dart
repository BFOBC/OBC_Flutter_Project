import 'package:broker_flutter_pp/ui/common/widgets/ProgressDialog.dart';
import 'package:flutter/material.dart';

void showProgressDialog(BuildContext context, {String message = 'Please wait...'}) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing the dialog by tapping outside
    builder: (BuildContext context) {
      return ProgressDialog(message: message);
    },
  );
}

void hideProgressDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop(); // Closes the dialog
}
