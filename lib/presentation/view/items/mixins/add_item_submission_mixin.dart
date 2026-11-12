import 'package:flutter/material.dart';
import 'package:maintenance_genie/app/routes/route_names.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/presentation/view_models/add_item_provider.dart';
import 'package:maintenance_genie/presentation/view_models/all_item_list_provider.dart';
import 'package:maintenance_genie/presentation/view_models/user_provider.dart';
import 'package:maintenance_genie/shared/common_widgets.dart';
import 'package:provider/provider.dart';

import '../widgets/show_item_added_dialog.dart';

mixin AddItemSubmissionMixin<T extends StatefulWidget> on State<T> {

  Future<void> submitItem(
      AddItemData data, {
        required VoidCallback onSaved,
        bool openQuestionFlowForPremium = false,
      }) async {
    final addItemProvider = context.read<AddItemProvider>();
    if (addItemProvider.isLoading) return;

    if (openQuestionFlowForPremium) {
      final isPremium =
          context.read<UserProvider>().userResponse?.data.isPremium == true;
      if (isPremium) {
        Navigator.pushNamed(
          context,
          RouteName.itemAddQuestion,
          arguments: data,
        );
        return;
      }
    }

    final allItems = context.read<AllItemListProvider>();
    final saved = await addItemProvider.addItem(data);
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