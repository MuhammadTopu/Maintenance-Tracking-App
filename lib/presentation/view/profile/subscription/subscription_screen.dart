import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/subscription/subscription_service.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_item_app_bar.dart';
import 'paywall_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const List<String> _premiumFeatures = [
    'Upcoming service',
    'Service Intervals',
    'Receipt Attachments',
    'Forum Suggestions',
    'Shop Suggestions',
    'Seasonal Suggestion',
  ];

  static const List<String> _freeFeatures = [
    'Upcoming service',
    'Service Intervals',
  ];

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SubscriptionService>();

    final yearly = service.annualPackage;
    final monthly = service.monthlyPackage;

    final isFree = !service.isPremium;
    final isYearlyCurrent = service.activePlanType == PackageType.annual;
    final isMonthlyCurrent = service.activePlanType == PackageType.monthly;

    // Real store price when available, fixed fallback otherwise.
    final yearlyPrice = yearly?.storeProduct.priceString ?? '\$50';
    final monthlyPrice = monthly?.storeProduct.priceString ?? '\$5';

    final savings = service.annualSavingsPercent;
    final yearlyTrial = yearly == null ? null : service.trialFor(yearly);
    final monthlyTrial = monthly == null ? null : service.trialFor(monthly);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
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
                      if (service.isPremium) ...[
                        _StatusBanner(service: service),
                        SizedBox(height: 16.h),
                      ],
                      Text(
                        'Current Plan',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _PlanCard(
                        title: 'Free Plan',
                        price: '\$0',
                        period: '/forever',
                        features: _freeFeatures,
                        isCurrent: isFree,
                      ),
                      SizedBox(height: 16.h),
                      _PlanCard(
                        title: 'Premium Yearly',
                        price: yearlyPrice,
                        period: '/year',
                        features: _premiumFeatures,
                        isCurrent: isYearlyCurrent,
                        tag: savings != null ? 'Save $savings%' : null,
                        trialLabel: yearlyTrial == null
                            ? null
                            : '${yearlyTrial.lengthLabel} free trial',
                        onTap: _canOpenPaywall(service, isYearlyCurrent)
                            ? () => _showPaywall(context)
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      _PlanCard(
                        title: 'Premium Monthly',
                        price: monthlyPrice,
                        period: '/month',
                        features: _premiumFeatures,
                        isCurrent: isMonthlyCurrent,
                        trialLabel: monthlyTrial == null
                            ? null
                            : '${monthlyTrial.lengthLabel} free trial',
                        onTap: _canOpenPaywall(service, isMonthlyCurrent)
                            ? () => _showPaywall(context)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              _BottomAction(
                service: service,
                onShowPaywall: () => _showPaywall(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canOpenPaywall(SubscriptionService service, bool isCurrent) =>
      !isCurrent && !service.isLifetime && !service.isBusy;

  Future<void> _showPaywall(BuildContext context) async {
    final purchased = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    if (!context.mounted) return;

    if (purchased == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to Premium!')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom button: paywall for free users, manage for subscribers
// ─────────────────────────────────────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.service, required this.onShowPaywall});

  final SubscriptionService service;
  final VoidCallback onShowPaywall;

  @override
  Widget build(BuildContext context) {
    // Lifetime owners have nothing to buy or manage.
    if (service.isLifetime) return const SizedBox.shrink();

    final isPremium = service.isPremium;
    final canManage = service.status.canManageInStore;

    // Premium from a promo grant: nothing to manage in the store.
    if (isPremium && !canManage) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      child: PrimaryButton(
        text: isPremium ? 'Manage Subscription' : 'Upgrade to Premium',
        onPressed: service.isBusy
            ? null
            : isPremium
            ? () => service.openManageSubscription()
            : onShowPaywall,
        child: service.isBusy
            ? SizedBox(
          height: 20.h,
          width: 20.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Renewal / trial / billing status for subscribers
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.service});

  final SubscriptionService service;

  @override
  Widget build(BuildContext context) {
    final status = service.status;
    final date = status.expirationDate;
    final fmt = DateFormat('MMM d, yyyy');

    String text;
    Color color;

    if (status.isLifetime) {
      text = 'You have Lifetime access.';
      color = Colors.green;
    } else if (status.hasBillingIssue) {
      text = 'There is a problem with your payment method. '
          'Update it in the store to keep Premium.';
      color = Colors.red;
    } else if (status.isInTrial && date != null) {
      text = status.willRenew
          ? 'Free trial ends on ${fmt.format(date)}, then it renews.'
          : 'Free trial ends on ${fmt.format(date)}. It will not renew.';
      color = Colors.blue;
    } else if (date != null) {
      text = status.willRenew
          ? 'Renews on ${fmt.format(date)}.'
          : 'Auto-renew is off. Premium ends on ${fmt.format(date)}.';
      color = status.willRenew ? Colors.green : Colors.orange;
    } else {
      text = 'Premium is active.';
      color = Colors.green;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xff1D1F2C),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrent;
  final String? tag; // e.g. "Save 17%"
  final String? trialLabel; // e.g. "7-day free trial"
  final VoidCallback? onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isCurrent,
    this.tag,
    this.trialLabel,
    this.onTap,
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
            color: isCurrent ? AppColors.primaryColor : Colors.grey.shade300,
            width: isCurrent ? 1.5 : 1,
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
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 4.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff1D1F2C),
                            ),
                          ),
                          if (isCurrent)
                            _Chip(text: 'Current', color: Colors.green),
                          if (tag != null)
                            _Chip(text: tag!, color: Colors.orange),
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
                      if (trialLabel != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          trialLabel!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusBadge(isCurrent: isCurrent),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isCurrent;

  const _StatusBadge({required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent ? Colors.green : Colors.grey.shade200,
      ),
      child: isCurrent
          ? Icon(Icons.check, size: 14.sp, color: Colors.white)
          : null,
    );
  }
}