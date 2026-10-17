import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/subscription/subscription_service.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_item_app_bar.dart';
import 'paywall_screen.dart';

const Color _gold = Color(0xffFFC857);

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
                child: RefreshIndicator(
                  color: AppColors.primaryColor,
                  // Re-fetches the entitlement + syncs with the backend.
                  onRefresh: () async {
                    try {
                      await service.onAppResumed();
                    } catch (e) {
                      debugPrint('Subscription refresh failed: $e');
                    }
                  },
                  child: service.isPremium
                      ? _PremiumView(
                    service: service,
                    features: _premiumFeatures,
                  )
                      : _FreeView(
                    service: service,
                    premiumFeatures: _premiumFeatures,
                    freeFeatures: _freeFeatures,
                    onShowPaywall: () => _showPaywall(context),
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

// ═════════════════════════════════════════════════════════════════════════════
// FREE USER VIEW: plan list, free plan marked as current
// ═════════════════════════════════════════════════════════════════════════════

class _FreeView extends StatelessWidget {
  const _FreeView({
    required this.service,
    required this.premiumFeatures,
    required this.freeFeatures,
    required this.onShowPaywall,
  });

  final SubscriptionService service;
  final List<String> premiumFeatures;
  final List<String> freeFeatures;
  final VoidCallback onShowPaywall;

  @override
  Widget build(BuildContext context) {
    final yearly = service.annualPackage;
    final monthly = service.monthlyPackage;

    // Real store price when available, fixed fallback otherwise.
    final yearlyPrice = yearly?.storeProduct.priceString ?? '\$50';
    final monthlyPrice = monthly?.storeProduct.priceString ?? '\$5';

    final savings = service.annualSavingsPercent;
    final yearlyTrial = yearly == null ? null : service.trialFor(yearly);
    final monthlyTrial = monthly == null ? null : service.trialFor(monthly);

    final canOpenPaywall = !service.isBusy;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
          _PlanCard(
            title: 'Free Plan',
            price: '\$0',
            period: '/forever',
            features: freeFeatures,
            isCurrent: true,
          ),
          SizedBox(height: 16.h),
          _PlanCard(
            title: 'Premium Yearly',
            price: yearlyPrice,
            period: '/year',
            features: premiumFeatures,
            isCurrent: false,
            tag: savings != null ? 'Save $savings%' : null,
            trialLabel: yearlyTrial == null
                ? null
                : '${yearlyTrial.lengthLabel} free trial',
            onTap: canOpenPaywall ? onShowPaywall : null,
          ),
          SizedBox(height: 16.h),
          _PlanCard(
            title: 'Premium Monthly',
            price: monthlyPrice,
            period: '/month',
            features: premiumFeatures,
            isCurrent: false,
            trialLabel: monthlyTrial == null
                ? null
                : '${monthlyTrial.lengthLabel} free trial',
            onTap: canOpenPaywall ? onShowPaywall : null,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM USER VIEW: only the current plan's details + live countdown
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumView extends StatelessWidget {
  const _PremiumView({required this.service, required this.features});

  final SubscriptionService service;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final status = service.status;
    final isLifetime = service.isLifetime || status.isLifetime;
    final planType = service.activePlanType;
    final isYearly = planType == PackageType.annual;
    final isMonthly = planType == PackageType.monthly;

    final yearlyPrice =
        service.annualPackage?.storeProduct.priceString ?? '\$50';
    final monthlyPrice =
        service.monthlyPackage?.storeProduct.priceString ?? '\$5';

    // Plan identity.
    late final String planName;
    String? price;
    String? period;
    Duration? billingPeriod;

    if (isLifetime) {
      planName = 'Premium Lifetime';
    } else if (isYearly) {
      planName = 'Premium Yearly';
      price = yearlyPrice;
      period = '/year';
      billingPeriod = const Duration(days: 365);
    } else if (isMonthly) {
      planName = 'Premium Monthly';
      price = monthlyPrice;
      period = '/month';
      billingPeriod = const Duration(days: 30);
    } else {
      planName = 'Premium';
    }

    // Status pill.
    late final String statusLabel;
    late final Color statusColor;
    if (status.hasBillingIssue) {
      statusLabel = 'Payment issue';
      statusColor = const Color(0xffFF6B6B);
    } else if (status.isInTrial) {
      statusLabel = 'Free trial';
      statusColor = const Color(0xff5AA9FF);
    } else if (!isLifetime && !status.willRenew) {
      statusLabel = 'Auto-renew off';
      statusColor = const Color(0xffFFA94D);
    } else {
      statusLabel = 'Active';
      statusColor = const Color(0xff4ADE80);
    }

    final expiry = status.expirationDate?.toLocal();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status.hasBillingIssue) ...[
            const _BillingIssueBanner(),
            SizedBox(height: 16.h),
          ],
          _PremiumHero(
            planName: planName,
            price: price,
            period: period,
            statusLabel: statusLabel,
            statusColor: statusColor,
            isLifetime: isLifetime,
            isTrial: status.isInTrial,
            expiry: expiry,
            billingPeriod: billingPeriod,
            // When the countdown reaches 00:00:00:00 the timer re-syncs with
            // RevenueCat (and retries a few times) so a renewal or expiry is
            // reflected automatically.
            onExpired: service.onAppResumed,
          ),
          SizedBox(height: 20.h),
          _DetailsCard(
            planName: planName,
            price: price,
            period: period,
            statusLabel: statusLabel,
            statusColor: statusColor,
            isLifetime: isLifetime,
            isTrial: status.isInTrial,
            willRenew: status.willRenew,
            expiry: expiry,
            isPromo: !status.canManageInStore && !isLifetime,
          ),
          SizedBox(height: 20.h),
          _BenefitsCard(features: features),
        ],
      ),
    );
  }
}

// ── Hero card ────────────────────────────────────────────────────────────────

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({
    required this.planName,
    required this.price,
    required this.period,
    required this.statusLabel,
    required this.statusColor,
    required this.isLifetime,
    required this.isTrial,
    required this.expiry,
    required this.billingPeriod,
    required this.onExpired,
  });

  final String planName;
  final String? price;
  final String? period;
  final String statusLabel;
  final Color statusColor;
  final bool isLifetime;
  final bool isTrial;
  final DateTime? expiry;
  final Duration? billingPeriod;
  final Future<void> Function() onExpired;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor;
    final dark = Color.lerp(primary, const Color(0xff0B1020), 0.65)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [dark, primary],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            Positioned(
              top: -50.h,
              right: -40.w,
              child: _GlowCircle(size: 160.w, alpha: 0.10),
            ),
            Positioned(
              bottom: -60.h,
              left: -40.w,
              child: _GlowCircle(size: 180.w, alpha: 0.07),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gold.withValues(alpha: 0.18),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 20.sp,
                          color: _gold,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'PREMIUM MEMBER',
                        style: TextStyle(
                          fontSize: 11.sp,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                          color: _gold,
                        ),
                      ),
                      const Spacer(),
                      _StatusPill(label: statusLabel, color: statusColor),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    planName,
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (price != null) ...[
                    SizedBox(height: 4.h),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: price,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' $period',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  Divider(color: Colors.white.withValues(alpha: 0.18)),
                  SizedBox(height: 14.h),
                  if (isLifetime)
                    Row(
                      children: [
                        Icon(Icons.all_inclusive_rounded,
                            color: _gold, size: 22.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'You have lifetime access. No renewal needed.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (expiry != null)
                    _CountdownTimer(
                      expiry: expiry!,
                      billingPeriod: isTrial ? null : billingPeriod,
                      caption: isTrial ? 'TRIAL ENDS IN' : 'TIME REMAINING',
                      onExpired: onExpired,
                    )
                  else
                    Text(
                      'Premium is active.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99.r),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live countdown ───────────────────────────────────────────────────────────

/// Starts when the screen opens: it reads the remaining time from [expiry]
/// right away, then ticks every second until the screen is closed (the timer
/// is cancelled in dispose). Computing from the clock on each tick keeps it
/// accurate after the app was in the background, and it re-syncs on its own
/// if [expiry] changes (e.g. after a renewal refresh).
class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({
    required this.expiry,
    required this.caption,
    required this.onExpired,
    this.billingPeriod,
  });

  final DateTime expiry;
  final String caption;
  final Duration? billingPeriod; // used for the progress bar; null hides it

  /// Refreshes the subscription state. Called when the countdown reaches zero.
  final Future<void> Function() onExpired;

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  static const int _maxRefreshAttempts = 4;
  static const Duration _retryDelay = Duration(seconds: 10);

  Timer? _timer;
  late Duration _remaining;
  bool _expiredNotified = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiry != widget.expiry) {
      _expiredNotified = false;
      _remaining = _computeRemaining();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _computeRemaining() {
    final diff = widget.expiry.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remaining == Duration.zero) {
      _notifyExpired();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _computeRemaining();
      setState(() => _remaining = remaining);
      if (remaining == Duration.zero) {
        _timer?.cancel();
        _notifyExpired();
      }
    });
  }

  void _notifyExpired() {
    if (_expiredNotified) return;
    _expiredNotified = true;
    // Defer so we never trigger provider updates during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshAfterExpiry());
    });
  }

  /// Refreshes the subscription state once the countdown is at zero.
  ///
  /// - Renewed: the new expiry arrives via didUpdateWidget and the countdown
  ///   restarts, so the loop below stops.
  /// - Expired: isPremium turns false, the screen switches to the free view
  ///   and this widget is disposed.
  /// - Store hasn't confirmed yet (grace period / delayed renewal): retry a
  ///   few times, then leave it to pull-to-refresh.
  Future<void> _refreshAfterExpiry() async {
    for (var attempt = 0; attempt < _maxRefreshAttempts; attempt++) {
      if (!mounted || _computeRemaining() != Duration.zero) return;

      setState(() => _refreshing = true);
      try {
        await widget.onExpired();
      } catch (e) {
        debugPrint('Auto refresh after expiry failed: $e');
      }
      if (!mounted) return;
      setState(() => _refreshing = false);

      if (attempt < _maxRefreshAttempts - 1) {
        await Future.delayed(_retryDelay);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    final total = widget.billingPeriod;
    double? progress;
    if (total != null && total.inSeconds > 0) {
      progress = (_remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    }

    if (_remaining == Duration.zero) {
      return Row(
        children: [
          if (_refreshing)
            SizedBox(
              width: 18.sp,
              height: 18.sp,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_gold),
              ),
            )
          else
            Icon(Icons.hourglass_bottom_rounded, color: _gold, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _refreshing
                  ? 'Subscription period ended. Updating your status…'
                  : 'Waiting for the store to confirm your renewal. '
                  'Pull down to refresh.',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 14.sp, color: _gold),
            SizedBox(width: 6.w),
            Text(
              widget.caption,
              style: TextStyle(
                fontSize: 11.sp,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _TimeTile(value: days, label: 'DAYS'),
            SizedBox(width: 8.w),
            _TimeTile(value: hours, label: 'HRS'),
            SizedBox(width: 8.w),
            _TimeTile(value: minutes, label: 'MIN'),
            SizedBox(width: 8.w),
            _TimeTile(value: seconds, label: 'SEC'),
          ],
        ),
        if (progress != null) ...[
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(99.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.h,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${(progress * 100).round()}% of this billing period left',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.sp,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Details card ─────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.planName,
    required this.price,
    required this.period,
    required this.statusLabel,
    required this.statusColor,
    required this.isLifetime,
    required this.isTrial,
    required this.willRenew,
    required this.expiry,
    required this.isPromo,
  });

  final String planName;
  final String? price;
  final String? period;
  final String statusLabel;
  final Color statusColor;
  final bool isLifetime;
  final bool isTrial;
  final bool willRenew;
  final DateTime? expiry;
  final bool isPromo;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');

    final rows = <_DetailRow>[
      _DetailRow(
        icon: Icons.workspace_premium_outlined,
        label: 'Plan',
        value: planName,
      ),
      if (price != null)
        _DetailRow(
          icon: Icons.payments_outlined,
          label: 'Price',
          value: '$price$period',
        ),
      _DetailRow(
        icon: Icons.verified_outlined,
        label: 'Status',
        value: statusLabel,
        valueColor: statusColor,
      ),
      if (!isLifetime && expiry != null) ...[
        _DetailRow(
          icon: Icons.event_available_outlined,
          label: isTrial
              ? 'Trial ends on'
              : willRenew
              ? 'Next renewal'
              : 'Valid until',
          value: dateFmt.format(expiry!),
        ),
        _DetailRow(
          icon: Icons.schedule_rounded,
          label: 'Time',
          value: timeFmt.format(expiry!),
        ),
        _DetailRow(
          icon: Icons.autorenew_rounded,
          label: 'Auto-renewal',
          value: willRenew ? 'On' : 'Off',
          valueColor: willRenew
              ? const Color(0xff16A34A)
              : const Color(0xffEA580C),
        ),
      ],
      if (isLifetime)
        const _DetailRow(
          icon: Icons.all_inclusive_rounded,
          label: 'Validity',
          value: 'Forever',
        ),
      if (isPromo)
        const _DetailRow(
          icon: Icons.card_giftcard_rounded,
          label: 'Access',
          value: 'Promotional',
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffE9E9EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 10.h, bottom: 4.h),
            child: Text(
              'Subscription details',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xff1D1F2C),
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, color: Color(0xffF0F0F2)),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 16.sp, color: AppColors.primaryColor),
          ),
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xff1D1F2C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Benefits + billing issue ────────────────────────────────────────────────

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xffFFFBF0),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18.sp, color: _gold),
              SizedBox(width: 8.w),
              Text(
                'Your Premium benefits',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff1D1F2C),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...features.map(
                (f) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold,
                    ),
                    child: Icon(Icons.check, size: 12.sp, color: Colors.white),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xff4A4C56),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingIssueBanner extends StatelessWidget {
  const _BillingIssueBanner();

  @override
  Widget build(BuildContext context) {
    const color = Colors.red;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: color, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'There is a problem with your payment method. '
                  'Update it in the store to keep Premium.',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xff1D1F2C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Bottom button: paywall for free users, manage for subscribers
// ═════════════════════════════════════════════════════════════════════════════

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

// ═════════════════════════════════════════════════════════════════════════════
// Plan card (free view)
// ═════════════════════════════════════════════════════════════════════════════

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
                            const _Chip(text: 'Current', color: Colors.green),
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
                    Icon(Icons.check,
                        size: 16.sp, color: Colors.green.shade600),
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
        color: color.withValues(alpha: 0.12),
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