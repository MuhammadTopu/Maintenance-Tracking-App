import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/app/routes/route_names.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/core/services/subscription/subscription_service.dart';
import 'package:maintenance_genie/presentation/view_models/all_item_list_provider.dart';
import 'package:maintenance_genie/presentation/view_models/login_provider.dart';
import 'package:maintenance_genie/presentation/view_models/parent_screen_provider.dart';
import 'package:provider/provider.dart';

Future<void> showLogoutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _LogoutDialog(),
  );
}

class _LogoutDialog extends StatefulWidget {
  const _LogoutDialog();

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    final navigator = Navigator.of(context);
    final loginProvider = context.read<LoginProvider>();
    final subscription = context.read<SubscriptionService>();
    final items = context.read<AllItemListProvider>();
    final parentScreens = context.read<ParentScreensProvider>();

    try {
      await loginProvider.logOut();
    } catch (e) {
      debugPrint('Logout cleanup failed: $e');
    }
    subscription.logOut();
    items.removeItems();
    parentScreens.onSelectedIndex(0);

    navigator.pushNamedAndRemoveUntil(RouteName.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loggingOut,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                ),
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 26.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Log out?',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'You will need to sign in again to access your assets '
                    'and tasks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      text: 'Cancel',
                      onTap: _loggingOut
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _DialogButton(
                      text: 'Log Out',
                      filled: true,
                      loading: _loggingOut,
                      onTap: _logout,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.text,
    required this.onTap,
    this.filled = false,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primaryColor : AppColors.cardColor,
      borderRadius: BorderRadius.circular(90.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(90.r),
        onTap: loading ? null : onTap,
        child: Container(
          height: 46.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(90.r),
            border: filled ? null : Border.all(color: const Color(0xffE9E9EA)),
          ),
          child: loading
              ? SizedBox(
            height: 18.h,
            width: 18.h,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : AppColors.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}