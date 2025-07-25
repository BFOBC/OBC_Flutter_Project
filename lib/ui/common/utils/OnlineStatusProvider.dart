import 'package:flutter/material.dart';

class OnlineStatusProvider with ChangeNotifier {
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    _isOnline = value;
    notifyListeners();
  }
}
