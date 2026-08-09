import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_item_app_bar.dart';
import '../../../view_models/subscription_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomItemAppBar(
                  title: 'Subscription',
                  onTap: Navigator.of(context).pop,
                ),
              ),
              SizedBox(height: 8.h),
              const Divider(color: Color(0xffE9E9EA), thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Consumer<SubscriptionProvider>(
                        builder: (context, provider, _) {
                          return Column(
                            children: [
                              _PlanCard(
                                title: 'Free Plan',
                                price: '\$0',
                                period: '/forever',
                                features: const [
                                  'Upcoming service',
                                  'Service Intervals',
                                ],
                                isCurrent: provider.currentPlan == SubscriptionPlan.free,
                                isSelected: provider.selectedPlan == SubscriptionPlan.free,
                                onTap: () => provider.selectPlan(SubscriptionPlan.free),
                              ),
                              SizedBox(height: 16.h),
                              _PlanCard(
                                title: 'Premium Plan',
                                price: '\$250',
                                period: '/year',
                                features: const [
                                  'Upcoming service',
                                  'Service Intervals',
                                  'Receipt Attachments',
                                  'Forum Suggestions',
                                  'Shop Suggestions',
                                  'Seasonal Suggestion',
                                ],
                                isCurrent: provider.currentPlan == SubscriptionPlan.premium,
                                isSelected: provider.selectedPlan == SubscriptionPlan.premium,
                                onTap: () => provider.selectPlan(SubscriptionPlan.premium),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: Consumer<SubscriptionProvider>(
                  builder: (context, provider, _) {
                    // Nothing to confirm: selected plan matches current plan.
                    if (!provider.hasPendingSelection) {
                      return const SizedBox.shrink();
                    }
                    final isUpgrade = provider.selectedPlan == SubscriptionPlan.premium;
                    return PrimaryButton(
                      text: isUpgrade ? 'Upgrade Now' : 'Switch to Free',
                      onPressed: provider.isUpgrading
                          ? null
                          : () async {
                        await provider.confirmSelection();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isUpgrade
                                    ? 'Upgraded to Premium!'
                                    : 'Switched to Free plan.',
                              ),
                            ),
                          );
                        }
                      },
                      child: provider.isUpgrading
                          ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff1D1F2C),
                            ),
                          ),
                          if (isCurrent) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(99.r),
                              ),
                              child: Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: price,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff1D1F2C),
                              ),
                            ),
                            TextSpan(
                              text: ' $period',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(isSelected: isSelected),
              ],
            ),
            SizedBox(height: 14.h),
            ...features.map(
                  (f) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 16.sp, color: Colors.green.shade600),
                    SizedBox(width: 8.w),
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff4A4C56),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isSelected;

  const _StatusBadge({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Colors.green : Colors.grey.shade200,
      ),
      child: isSelected
          ? Icon(Icons.check, size: 14.sp, color: Colors.white)
          : null,
    );
  }
}