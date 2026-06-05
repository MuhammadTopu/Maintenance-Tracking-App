import 'package:flutter/cupertino.dart';

class SplashProvider extends ChangeNotifier {
  bool _showContent = false;

  bool get showContent => _showContent;

  void displayContent() {
    _showContent = true;
    notifyListeners(); // Notify listeners to rebuild
  }
}
