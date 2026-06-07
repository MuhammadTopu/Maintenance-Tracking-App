import 'package:flutter/material.dart';

import '../view/dashboard/dashboard_screen.dart';
import '../view/items/items_menu_screen.dart';
import '../view/profile/profile_menu.dart';
import '../view/tracking/tracking_screen.dart';

class ParentScreensProvider with ChangeNotifier {
  List<Widget> screens = [
    DashboardScreen(),
    ItemsMenuScreen(),
    TrackingScreen(),
    ProfileMenu(),
  ];
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void onSelectedIndex(int selectedIndex) {
    _selectedIndex = selectedIndex;
    notifyListeners();
    debugPrint("Selected Index: $selectedIndex");
  }
}
