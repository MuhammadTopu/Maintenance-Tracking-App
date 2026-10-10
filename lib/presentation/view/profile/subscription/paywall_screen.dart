import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../../core/services/subscription/subscription_service.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<SubscriptionService>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: PaywallView(
          offering: service.offering,
          displayCloseButton: false,
          onPurchaseCompleted: (customerInfo, transaction) async {
            await service.refreshCustomerInfo(force: true);
            if (context.mounted) Navigator.of(context).pop(true);
          },
          onRestoreCompleted: (customerInfo) async {
            await service.refreshCustomerInfo(force: true);
            if (context.mounted) Navigator.of(context).pop(service.isPremium);
          },
          onDismiss: () {
            if (context.mounted) Navigator.of(context).pop(false);
          },
        ),
      ),
    );
  }
}