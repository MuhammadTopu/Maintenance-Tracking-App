import 'package:flutter/material.dart';

enum SubscriptionPlan { free, premium }

class SubscriptionProvider extends ChangeNotifier {
  // The plan the backend/user account currently has.
  // Swap this out later with real data from your auth/user provider.
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;

  // The plan the user has tapped/selected on this screen, which may
  // differ from currentPlan until they confirm the upgrade.
  late SubscriptionPlan _selectedPlan = _currentPlan;

  SubscriptionPlan get currentPlan => _currentPlan;
  SubscriptionPlan get selectedPlan => _selectedPlan;

  bool get isPremium => _currentPlan == SubscriptionPlan.premium;

  // Whether the user picked a plan different from their current one,
  // i.e. there's something to confirm/upgrade to.
  bool get hasPendingSelection => _selectedPlan != _currentPlan;

  bool _isUpgrading = false;
  bool get isUpgrading => _isUpgrading;

  void selectPlan(SubscriptionPlan plan) {
    if (_selectedPlan == plan || _isUpgrading) return;
    _selectedPlan = plan;
    notifyListeners();
  }

  Future<void> confirmSelection() async {
    if (_isUpgrading || !hasPendingSelection) return;
    _isUpgrading = true;
    notifyListeners();

    // TODO: hook up real payment/upgrade flow here.
    await Future.delayed(const Duration(seconds: 1));

    _currentPlan = _selectedPlan;
    _isUpgrading = false;
    notifyListeners();
  }

  // Reset the pending selection back to whatever the user currently has,
  // e.g. call this if they navigate away without confirming.
  void resetSelection() {
    _selectedPlan = _currentPlan;
    notifyListeners();
  }
}