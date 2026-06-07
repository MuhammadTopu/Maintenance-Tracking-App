import 'package:flutter/material.dart';

import '../../../../shared/common_widgets.dart';

class ItemAddedDialog extends StatelessWidget {
  final VoidCallback onDone;
  final bool isPremium;
  const ItemAddedDialog({
    super.key,
    required this.onDone,
    required this.isPremium,
  });
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              isPremium
                  ? "Item Added Successfully"
                  : "Item Added Successfully. Cant Generate Task. Upgrade to Premium",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(text: 'Done', onPressed: onDone),
            ),
          ],
        ),
      ),
    );
  }
}
