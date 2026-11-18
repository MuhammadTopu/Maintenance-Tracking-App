import 'package:flutter/material.dart';
import 'package:maintenance_genie/app/routes/route_names.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/presentation/view_models/add_item_provider.dart';
import 'package:maintenance_genie/presentation/view_models/all_item_list_provider.dart';
import 'package:maintenance_genie/shared/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/role/role_service.dart';
import '../../../../core/services/role/user_role.dart';
import '../widgets/show_item_added_dialog.dart';

/// Submit flow shared by the Vehicle, Home and Other forms, so the three forms
/// cannot drift apart.
mixin AddItemSubmissionMixin<T extends StatefulWidget> on State<T> {
  /// Saves [data].
  ///
  ///  * Free user: saves the item, refreshes the list and shows the "item
  ///    added" dialog.
  ///  * Premium user ([openQuestionFlowForPremium]): opens the question flow,
  ///    which saves the item itself and then asks its maintenance questions
  ///    (Vehicle: Yes / No / Planned. Home and Other: typed questions, then a
  ///    review of the answers).
  ///
  /// [onSaved] resets the form. It runs once the item exists, in both cases.
  Future<void> submitItem(
      AddItemData data, {
        required VoidCallback onSaved,
        bool openQuestionFlowForPremium = false,
      }) async {
    final addItemProvider = context.read<AddItemProvider>();
    if (addItemProvider.isLoading) return;

    if (openQuestionFlowForPremium) {
      // The role comes from RevenueCat (RoleService), not from /get-me.
      final canGenerateTasks = context.read<RoleService>().can(
        AppFeature.taskGeneration,
      );
      if (canGenerateTasks) {
        // The question screen pops `true` once the item is saved, even if the
        // user then leaves without finishing the questions. Reset the form in
        // that case: the item exists, so submitting the same form again would
        // create a duplicate.
        final itemSaved = await Navigator.pushNamed(
          context,
          RouteName.itemAddQuestion,
          arguments: data,
        );
        if (itemSaved == true && mounted) {
          addItemProvider.clearFields();
          onSaved();
        }
        return;
      }
    }

    final allItems = context.read<AllItemListProvider>();
    final saved = await addItemProvider.addItem(data);
    // On failure the repository has already shown the reason.
    if (!mounted || !saved) return;

    allItems.getAllItem();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ItemAddedDialog(
        onDone: () => Navigator.popAndPushNamed(context, RouteName.parent),
        isPremium: false,
      ),
    );
    addItemProvider.clearFields();
    onSaved();
  }

  /// The "Add Asset" button. Swaps to a spinner while a request is running so
  /// the user cannot submit twice.
  Widget buildSubmitButton({required VoidCallback onPressed}) {
    return Selector<AddItemProvider, bool>(
      selector: (_, p) => p.isLoading,
      builder: (_, isLoading, __) => Visibility(
        visible: !isLoading,
        replacement: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
        child: SizedBox(
          width: double.infinity,
          child: PrimaryButton(text: 'Add Asset', onPressed: onPressed),
        ),
      ),
    );
  }
}