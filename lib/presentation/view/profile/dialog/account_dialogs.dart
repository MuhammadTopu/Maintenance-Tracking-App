import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/domain/repository/support_mail_repository.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/services/subscription/subscription_service.dart';
import '../../../../shared/app_toast.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_text_field.dart';
import '../../../view_models/all_item_list_provider.dart';
import '../../../view_models/item_task_list_provider.dart';
import '../../../view_models/login_provider.dart';
import '../../../view_models/parent_screen_provider.dart';
import '../../items/widgets/custom_drop_down_field.dart';

int countWords(String text) {
  final t = text.trim();
  return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
}

class WordLimitFormatter extends TextInputFormatter {
  final int maxWords;
  WordLimitFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return countWords(newValue.text) > maxWords ? oldValue : newValue;
  }
}

Widget _btnLoader() => SizedBox(
  width: 20.w,
  height: 20.w,
  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
);

/// ---------------- DELETE ACCOUNT ----------------
Future<void> showDeleteAccountDialog(
  BuildContext context,
  SupportMailRepository repository,
) {
  final navigator = Navigator.of(context);
  final loginProvider = context.read<LoginProvider>();
  final subscription = context.read<SubscriptionService>();
  final items = context.read<AllItemListProvider>();
  final tasks = context.read<ItemTaskListProvider>();
  final parentScreens = context.read<ParentScreensProvider>();

  const maxWords = 200;
  final formKey = GlobalKey<FormState>();
  final passwordCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();
  bool isLoading = false;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (_, setState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setState(() => isLoading = true);

            final ok = await repository.deleteAccount(
              password: passwordCtrl.text.trim(),
              reason: reasonCtrl.text.trim(),
            );

            if (!dialogContext.mounted) return;
            setState(() => isLoading = false);

            if (ok) {
              Navigator.pop(dialogContext);
              AppToast.showToast(
                'Your account has been deleted',
                backgroundColor: Colors.green,
              );

              try {
                await loginProvider.logOut();
              } catch (e) {
                debugPrint('Delete account cleanup failed: $e');
              }
              subscription.logOut();
              items.removeItems();
              tasks.reset();
              parentScreens.onSelectedIndex(0);

              navigator.pushNamedAndRemoveUntil(RouteName.login, (_) => false);
            }
          }

          return PopScope(
            canPop: !isLoading,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(dialogContext).size.width * 0.05,
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 52.w,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Delete Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'This action cannot be undone. '
                          'Your account will be deleted, but you have a 30-day grace period. '
                          'If you log in within 30 days, your account and all your data will be restored. '
                          'After 30 days, your account and data will be permanently deleted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          title: 'Password',
                          hintText: 'Enter your password',
                          obscureText: true,
                          controller: passwordCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Password is required'
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        CustomTextField(
                          title: 'Reason',
                          hintText: 'Why are you leaving?',
                          controller: reasonCtrl,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          inputFormatters: [WordLimitFormatter(maxWords)],
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Reason is required'
                              : null,
                        ),
                        SizedBox(height: 4.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${countWords(reasonCtrl.text)}/$maxWords words',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: countWords(reasonCtrl.text) >= maxWords
                                  ? Colors.red
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'Cancel',
                                variant: ButtonVariant.outlined,
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Delete',
                                backgroundColor: Colors.red,
                                onPressed: isLoading ? null : submit,
                                child: isLoading ? _btnLoader() : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    Future.delayed(const Duration(milliseconds: 500), () {
      passwordCtrl.dispose();
      reasonCtrl.dispose();
    });
  });
}

/// ---------------- REPORT AN ISSUE ----------------
Future<void> showReportIssueDialog(
  BuildContext context,
  SupportMailRepository repository,
) {
  final formKey = GlobalKey<FormState>();
  final subjectCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  bool isLoading = false;

  const issueTypes = [
    'bug',
    'crash',
    'performance',
    'ui_issue',
    'ai_suggestions',
    'notifications',
    'payment',
    'account',
    'feature_request',
    'other',
  ];
  String? selectedType;
  bool typeError = false;

  String? requiredField(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (_, setState) {
          Future<void> submit() async {
            final formValid = formKey.currentState!.validate();
            if (selectedType == null) {
              setState(() => typeError = true);
            }
            if (!formValid || selectedType == null) return;

            setState(() => isLoading = true);

            final ok = await repository.reportIssue(
              type: selectedType!,
              subject: subjectCtrl.text.trim(),
              description: descCtrl.text.trim(),
            );

            if (!dialogContext.mounted) return;
            setState(() => isLoading = false);

            if (ok) {
              Navigator.pop(dialogContext);
              AppToast.showToast(
                'Report submitted. Thank you!',
                backgroundColor: Colors.green,
              );
            }
          }

          return PopScope(
            canPop: !isLoading,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(dialogContext).size.width * 0.05,
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Report an Issue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        CustomPopupDropdown(
                          title: 'Issue Type',
                          hint: 'Select issue type',
                          value: selectedType,
                          items: issueTypes,
                          menuHeight: 250,
                          onChanged: (v) => setState(() {
                            selectedType = v;
                            typeError = false;
                          }),
                          onDisabledTap: isLoading ? () {} : null,
                        ),
                        if (typeError)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h, left: 12.w),
                            child: Text(
                              'Issue type is required',
                              style: TextStyle(fontSize: 12.sp, color: Colors.red),
                            ),
                          ),
                        SizedBox(height: 12.h),
                        CustomTextField(
                          title: 'Subject',
                          hintText: 'Short summary of the issue',
                          controller: subjectCtrl,
                          validator: (v) => requiredField(v, 'Subject'),
                        ),
                        SizedBox(height: 12.h),
                        CustomTextField(
                          title: 'Description',
                          hintText: 'Describe what happened',
                          controller: descCtrl,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          validator: (v) => requiredField(v, 'Description'),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'Cancel',
                                variant: ButtonVariant.outlined,
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Report',
                                onPressed: isLoading ? null : submit,
                                child: isLoading ? _btnLoader() : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    Future.delayed(const Duration(milliseconds: 500), () {
      subjectCtrl.dispose();
      descCtrl.dispose();
    });
  });
}
