// ════════════════════════════════════════════════════════════════════════════
// subscription_service.dart
//
// Universal RevenueCat subscription service for Flutter (Android + iOS).
// Project-agnostic: no backend, storage or routing is hard-coded. Everything
// project-specific goes through [SubscriptionConfig] and optional callbacks.
//
// Covers: init/configure, login/logout, offerings, monthly/annual/lifetime
// packages, free-trial detection, purchase, upgrade/downgrade (with Android
// proration), restore, cancel (store deep link), customer info + live
// listener, expiry/billing-issue state, RevenueCat Paywalls, offer codes.
//
// pubspec.yaml:
//   purchases_flutter: ^8.0.0      (or newer)
//   purchases_ui_flutter: ^8.0.0   (same major as purchases_flutter)
//   url_launcher: ^6.2.0
//   intl: ^0.19.0
//
// iOS:     enable the "In-App Purchase" capability in Xcode.
// Android: add <uses-permission android:name="com.android.vending.BILLING"/>
//          (purchases_flutter adds it automatically) and use a FragmentActivity
//          based MainActivity if you use the RevenueCat paywall UI.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionConfig {
  const SubscriptionConfig({
    required this.entitlementId,
    this.androidApiKey = '',
    this.iosApiKey = '',
    this.offeringId,
    this.lifetimeProductIds = const {},
    this.androidPackageName,
    this.debugLogs = kDebugMode,
  });

  /// Entitlement identifier from the RevenueCat dashboard (e.g. "premium").
  final String entitlementId;

  /// Public SDK keys (Project settings → API keys). Use the platform keys
  /// (goog_… / appl_…), never the secret key.
  final String androidApiKey;
  final String iosApiKey;

  /// Offering to show. Null = the offering marked "Current" in the dashboard.
  final String? offeringId;

  /// Product ids that are one-time lifetime purchases. Any entitlement without
  /// an expiration date is also treated as lifetime.
  final Set<String> lifetimeProductIds;

  /// Needed only for the Google Play "manage subscription" fallback link.
  final String? androidPackageName;

  final bool debugLogs;
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics hook (override only what you need)
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionAnalytics {
  const SubscriptionAnalytics();
  void paywallViewed() {}
  void purchaseStarted(String productId) {}
  void trialStarted(String productId) {}
  void purchaseCompleted(String productId, {required bool wasTrial}) {}
  void purchaseFailed(String productId, String reasonCode) {}
  void purchaseCancelled(String productId) {}
  void restoreCompleted({required bool foundActiveSubscription}) {}
  void planChanged({required String fromProductId, required String toProductId}) {}
}

/// Called whenever the entitlement meaningfully changes (premium flips,
/// renewal, plan switch, auto-renew toggled). Use it to sync your backend.
/// The backend must still verify with RevenueCat (webhook / REST API).
typedef SubscriptionStatusCallback = FutureOr<void> Function(
    SubscriptionStatus status);

// ─────────────────────────────────────────────────────────────────────────────
// Results
// ─────────────────────────────────────────────────────────────────────────────

enum PurchaseOutcomeStatus {
  /// User now has an active entitlement.
  success,
  cancelled,

  /// Waiting for approval (Google Play pending / Ask to Buy).
  pending,

  /// Already subscribed to that plan / already owns lifetime.
  alreadyOwned,
  notAvailable,
  failed,
}

class PurchaseOutcome {
  const PurchaseOutcome(this.status, {this.message, this.errorCode});

  final PurchaseOutcomeStatus status;
  final String? message;
  final String? errorCode;

  bool get isSuccess => status == PurchaseOutcomeStatus.success;
  bool get isCancelled => status == PurchaseOutcomeStatus.cancelled;
  bool get isPending => status == PurchaseOutcomeStatus.pending;

  @override
  String toString() => 'PurchaseOutcome($status, $message)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Status snapshot (immutable, built from CustomerInfo)
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.appUserId,
    required this.isAnonymous,
    required this.isLifetime,
    this.entitlement,
    this.managementUrl,
  });

  static const SubscriptionStatus free = SubscriptionStatus(
    appUserId: null,
    isAnonymous: true,
    isLifetime: false,
  );

  final String? appUserId;
  final bool isAnonymous;
  final bool isLifetime;
  final EntitlementInfo? entitlement;
  final String? managementUrl;

  bool get isPremium => entitlement != null;
  bool get isInTrial => entitlement?.periodType == PeriodType.trial;
  bool get isInIntroPrice => entitlement?.periodType == PeriodType.intro;
  bool get willRenew => entitlement?.willRenew ?? false;
  bool get isSandbox => entitlement?.isSandbox ?? false;
  bool get hasBillingIssue => entitlement?.billingIssueDetectedAt != null;
  String? get productId => entitlement?.productIdentifier;
  Store? get store => entitlement?.store;
  bool get isPromotional => entitlement?.store == Store.promotional;

  /// Subscription whose auto-renew is off: access continues until [expirationDate].
  bool get renewalTurnedOff => isPremium && !isLifetime && !willRenew;

  /// Real store subscription the user can manage in Play / App Store.
  bool get canManageInStore => isPremium && !isLifetime && !isPromotional;

  DateTime? get expirationDate {
    final raw = entitlement?.expirationDate;
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  DateTime? get originalPurchaseDate =>
      DateTime.tryParse(entitlement?.originalPurchaseDate ?? '')?.toLocal();

  DateTime? get latestPurchaseDate =>
      DateTime.tryParse(entitlement?.latestPurchaseDate ?? '')?.toLocal();

  DateTime? get unsubscribeDetectedAt =>
      DateTime.tryParse(entitlement?.unsubscribeDetectedAt ?? '')?.toLocal();

  Duration? get remainingTime {
    final exp = expirationDate;
    if (exp == null) return null;
    final d = exp.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  int? get daysRemaining => remainingTime?.inDays;

  /// Changes whenever something the app/back-end cares about changes.
  String get signature => [
    appUserId,
    isPremium,
    entitlement?.productIdentifier,
    entitlement?.expirationDate,
    entitlement?.willRenew,
    entitlement?.periodType,
    entitlement?.billingIssueDetectedAt,
  ].join('|');
}

/// Free-trial info for a package (already filtered by store eligibility).
class TrialInfo {
  const TrialInfo({required this.lengthLabel, required this.iso8601});
  final String lengthLabel; // e.g. "7-day"
  final String iso8601; // e.g. "P7D"
}

enum BusyAction { none, purchasing, changingPlan, restoring, identifying }

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionService extends ChangeNotifier {
  SubscriptionService({
    required this.config,
    this.analytics = const SubscriptionAnalytics(),
    this.onStatusChanged,
  });

  final SubscriptionConfig config;
  final SubscriptionAnalytics analytics;
  final SubscriptionStatusCallback? onStatusChanged;

  // ── State ──────────────────────────────────────────────────────────────
  SubscriptionStatus _status = SubscriptionStatus.free;
  Offering? _offering;
  bool _offeringsLoading = false;
  bool _initialized = false;
  bool _customerInfoResolved = false;
  BusyAction _busy = BusyAction.none;
  String? _errorMessage;
  CustomerInfo? _customerInfo;

  /// iOS only: store-confirmed intro/trial eligibility per product id.
  final Map<String, bool> _storeTrialEligibility = {};

  String? _lastSignature;
  bool _awaitingReturnFromStore = false;
  bool _purchaseLock = false; // synchronous double-tap guard
  bool _listenerAttached = false;
  bool _disposed = false;
  Future<void>? _initFuture;

  final StreamController<SubscriptionStatus> _statusController =
  StreamController<SubscriptionStatus>.broadcast();

  // ── Public state ───────────────────────────────────────────────────────
  SubscriptionStatus get status => _status;
  Stream<SubscriptionStatus> get statusStream => _statusController.stream;
  CustomerInfo? get customerInfo => _customerInfo;

  bool get isInitialized => _initialized;

  /// True once RevenueCat has answered at least once (use to avoid flashing
  /// a "free" UI to a paying user on cold start).
  bool get hasResolved => _customerInfoResolved;

  bool get isPremium => _status.isPremium;
  bool get isLifetime => _status.isLifetime;
  bool get isInTrial => _status.isInTrial;
  bool get willRenew => _status.willRenew;
  String? get errorMessage => _errorMessage;

  bool get offeringsLoading => _offeringsLoading;
  bool get hasOfferings => packages.isNotEmpty;
  Offering? get offering => _offering;

  BusyAction get busyAction => _busy;
  bool get isBusy => _busy != BusyAction.none;

  // ── Packages ───────────────────────────────────────────────────────────
  Package? get monthlyPackage => _offering?.monthly;
  Package? get annualPackage => _offering?.annual;
  Package? get lifetimePackage => _offering?.lifetime;

  /// Monthly → Annual → Lifetime (only the ones that exist).
  List<Package> get packages => [
    if (monthlyPackage != null) monthlyPackage!,
    if (annualPackage != null) annualPackage!,
    if (lifetimePackage != null) lifetimePackage!,
  ];

  Package? packageOfType(PackageType type) =>
      packages.where((p) => p.packageType == type).firstOrNull;

  bool isLifetimePackage(Package p) =>
      p.packageType == PackageType.lifetime ||
          config.lifetimeProductIds.contains(p.storeProduct.identifier);

  /// Package matching the user's active entitlement, if any.
  Package? get activePackage {
    if (!isPremium) return null;
    return packages.where(_entitlementMatchesPackage).firstOrNull;
  }

  bool isCurrentPlan(Package p) => isPremium && _entitlementMatchesPackage(p);

  /// Plan type derived from the entitlement itself, so it works even when
  /// offerings failed to load.
  PackageType? get activePlanType {
    if (!isPremium) return null;
    if (isLifetime) return PackageType.lifetime;
    final pkg = activePackage;
    if (pkg != null) return pkg.packageType;
    final id = (_status.productId ?? '').toLowerCase();
    if (id.contains('annual') || id.contains('year')) return PackageType.annual;
    if (id.contains('month')) return PackageType.monthly;
    if (id.contains('week')) return PackageType.weekly;
    return null;
  }

  /// Subscriber buying Lifetime while their subscription still renews:
  /// show a warning in the UI, otherwise they'd be billed twice.
  bool needsLifetimeOverlapWarning(Package target) =>
      isPremium && !isLifetime && isLifetimePackage(target) && willRenew;

  // ── Pricing helpers ────────────────────────────────────────────────────
  String priceStringFor(Package p) => p.storeProduct.priceString;

  String? periodLabelFor(Package p) {
    switch (p.packageType) {
      case PackageType.monthly:
        return 'month';
      case PackageType.annual:
        return 'year';
      case PackageType.weekly:
        return 'week';
      default:
        return null;
    }
  }

  /// Annual plan expressed per month, in the store currency (e.g. "$4.17").
  String? monthlyEquivalentFor(Package p) {
    if (p.packageType != PackageType.annual) return null;
    final product = p.storeProduct;
    final perMonth = product.price / 12;
    if (perMonth <= 0) return null;
    try {
      return NumberFormat.simpleCurrency(name: product.currencyCode)
          .format(perMonth);
    } catch (_) {
      return null;
    }
  }

  /// Savings of annual vs. paying monthly for 12 months (e.g. 17 for $5 / $50).
  int? get annualSavingsPercent {
    final m = monthlyPackage?.storeProduct.price;
    final a = annualPackage?.storeProduct.price;
    if (m == null || a == null || m <= 0) return null;
    final pct = (1 - a / (m * 12)) * 100;
    return pct > 0 ? pct.round() : null;
  }

  // ── Free trial helpers ─────────────────────────────────────────────────

  /// Free trial the CURRENT user can actually get for [package], or null.
  /// Android: Google only returns offers the user is eligible for.
  /// iOS: confirmed through Apple's intro-offer eligibility check.
  TrialInfo? trialFor(Package package) {
    if (isLifetimePackage(package) || isPremium) return null;
    final product = package.storeProduct;

    // Android (base plan + offers) and iOS 2.0 subscription options.
    final options = product.subscriptionOptions;
    if (options != null) {
      for (final option in options) {
        final iso = option.freePhase?.billingPeriod?.iso8601;
        if (iso != null && _trialAllowed(product.identifier)) {
          return TrialInfo(lengthLabel: _humanizePeriod(iso), iso8601: iso);
        }
      }
    }

    // iOS introductory offer priced at zero == free trial.
    final intro = product.introductoryPrice;
    if (intro != null &&
        intro.price == 0 &&
        _trialAllowed(product.identifier)) {
      return TrialInfo(
        lengthLabel: _humanizePeriod(intro.period),
        iso8601: intro.period,
      );
    }
    return null;
  }

  bool offersFreeTrial(Package package) => trialFor(package) != null;

  bool _trialAllowed(String productId) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return true;
    return _storeTrialEligibility[productId] ?? false;
  }

  String _humanizePeriod(String iso) {
    final m = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$')
        .firstMatch(iso);
    if (m == null) return iso;
    final years = int.tryParse(m.group(1) ?? '') ?? 0;
    final months = int.tryParse(m.group(2) ?? '') ?? 0;
    final weeks = int.tryParse(m.group(3) ?? '') ?? 0;
    final days = int.tryParse(m.group(4) ?? '') ?? 0;
    if (years > 0) return '$years-year';
    if (months > 0) return '$months-month';
    if (weeks > 0) return '${weeks * 7}-day';
    if (days > 0) return '$days-day';
    return iso;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════

  /// Configure RevenueCat and load offerings + customer info.
  /// Safe to call many times (hot restart, retry after failure).
  ///
  /// Pass [appUserId] if the user is already logged in at launch; otherwise
  /// RevenueCat creates an anonymous id and you call [logIn] later.
  Future<void> init({String? appUserId}) {
    return _initFuture ??= _init(appUserId).whenComplete(() => _initFuture = null);
  }

  Future<void> _init(String? appUserId) async {
    if (!_initialized) {
      final key = _apiKeyForPlatform();
      if (key.isEmpty) {
        _setError('RevenueCat API key is missing for this platform.');
        return;
      }

      if (config.debugLogs) await Purchases.setLogLevel(LogLevel.debug);

      final alreadyConfigured = await Purchases.isConfigured;
      if (!alreadyConfigured) {
        final configuration = PurchasesConfiguration(key);
        if (appUserId != null && appUserId.trim().isNotEmpty) {
          configuration.appUserID = appUserId;
        }
        await Purchases.configure(configuration);
      }
      _initialized = true;
    }

    _attachListener();
    await Future.wait([fetchOfferings(), refreshCustomerInfo(force: true)]);
  }

  String _apiKeyForPlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return config.androidApiKey;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return config.iosApiKey;
      default:
        return '';
    }
  }

  void _attachListener() {
    if (_listenerAttached) return;
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
    _listenerAttached = true;
  }

  void _onCustomerInfo(CustomerInfo info) {
    unawaited(_applyCustomerInfo(info));
  }

  /// Call from your app's lifecycle observer on `AppLifecycleState.resumed`.
  /// Covers coming back from the store's manage-subscription page and renewals.
  Future<void> onAppResumed() async {
    if (_disposed || !_initialized) return;
    final cameBack = _awaitingReturnFromStore;
    _awaitingReturnFromStore = false;
    await refreshCustomerInfo(force: cameBack);
    if (cameBack) unawaited(_pollAfterStoreReturn());
    if (!hasOfferings) unawaited(fetchOfferings());
  }

  /// Store notifications reach RevenueCat a few seconds late.
  Future<void> _pollAfterStoreReturn() async {
    for (final seconds in const [3, 6]) {
      await Future<void>.delayed(Duration(seconds: seconds));
      if (_disposed) return;
      await refreshCustomerInfo(force: true);
    }
  }

  /// Call periodically (or on resume): local state goes stale if the app
  /// stays open past the expiry date.
  Future<void> refreshIfExpiryPassed() async {
    final exp = _status.expirationDate;
    if (exp != null && DateTime.now().isAfter(exp)) {
      await refreshCustomerInfo(force: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_listenerAttached) {
      Purchases.removeCustomerInfoUpdateListener(_onCustomerInfo);
      _listenerAttached = false;
    }
    unawaited(_statusController.close());
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    _notify();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notify();
  }

  void _log(String message) {
    if (config.debugLogs) debugPrint('[Subscription] $message');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // User identity
  // ═══════════════════════════════════════════════════════════════════════

  /// Link purchases to your own user id after login. Returns true on success.
  /// Use a stable, non-guessable id (your DB user id), never an email.
  Future<bool> logIn(String appUserId) async {
    if (appUserId.trim().isEmpty) {
      _setError('Invalid user id.');
      return false;
    }

    // NEW: wait for configure() if it is still running
    if (!_initialized) await init();
    if (!_initialized) return false;

    // NEW: already linked to this user, nothing to do
    if (!_status.isAnonymous && _status.appUserId == appUserId) return true;

    if (_busy != BusyAction.none) return false;

    _busy = BusyAction.identifying;
    _errorMessage = null;
    _notify();
    try {
      final result = await Purchases.logIn(appUserId);
      await _applyCustomerInfo(result.customerInfo);
      await Future.wait([fetchOfferings(), refreshCustomerInfo(force: true)]);
      return true;
    } on PlatformException catch (e) {
      _errorMessage = _messageFor(
        e,
        fallback: 'Could not link your account for purchases.',
      );
      return false;
    } catch (e) {
      _log('logIn failed: $e');
      _errorMessage = 'Could not link your account. Please try again.';
      return false;
    } finally {
      _busy = BusyAction.none;
      _notify();
    }
  }

  /// Call on app logout so the next user never sees the previous user's state.
  Future<void> logOut() async {
    _busy = BusyAction.identifying;
    _notify();
    try {
      if (!await Purchases.isAnonymous) await Purchases.logOut();
    } catch (e) {
      _log('logOut failed (clearing local state anyway): $e');
    }
    _clearUserState();
    try {
      await Future.wait([fetchOfferings(), refreshCustomerInfo(force: true)]);
    } catch (_) {}
    _busy = BusyAction.none;
    _notify();
  }

  void _clearUserState() {
    _status = SubscriptionStatus.free;
    _customerInfo = null;
    _customerInfoResolved = false;
    _lastSignature = null;
    _awaitingReturnFromStore = false;
    _storeTrialEligibility.clear();
    _errorMessage = null;
    if (!_statusController.isClosed) _statusController.add(_status);
    _notify();
  }

  /// Optional subscriber attributes (shown in the RevenueCat dashboard and
  /// forwarded to integrations).
  Future<void> setUserDetails({
    String? email,
    String? displayName,
    Map<String, String>? attributes,
  }) async {
    try {
      if (email != null) await Purchases.setEmail(email);
      if (displayName != null) await Purchases.setDisplayName(displayName);
      if (attributes != null) await Purchases.setAttributes(attributes);
    } catch (e) {
      _log('setUserDetails failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Offerings & customer info
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> fetchOfferings() async {
    if (!_initialized) return;
    _offeringsLoading = true;
    _notify();
    try {
      final offerings = await Purchases.getOfferings();
      final id = config.offeringId;
      _offering =
          (id != null ? offerings.getOffering(id) : null) ?? offerings.current;
      if (_offering == null || packages.isEmpty) {
        _errorMessage = 'No plans are available right now.';
      } else {
        _errorMessage = null;
        unawaited(_refreshStoreTrialEligibility());
      }
    } on PlatformException catch (e) {
      _errorMessage = _messageFor(e, fallback: 'Could not load plans.');
    } catch (e) {
      _log('fetchOfferings failed: $e');
      _errorMessage = 'Could not load plans. Check your connection.';
    } finally {
      _offeringsLoading = false;
      _notify();
    }
  }

  /// iOS: ask Apple whether this Apple ID can still get the intro/trial offer,
  /// so a free trial is never advertised if Apple will not grant it.
  Future<void> _refreshStoreTrialEligibility() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final ids = packages
          .where((p) => !isLifetimePackage(p))
          .map((p) => p.storeProduct.identifier)
          .toList();
      if (ids.isEmpty) return;
      final result = await Purchases.checkTrialOrIntroductoryPriceEligibility(ids);
      _storeTrialEligibility.clear();
      result.forEach((id, eligibility) {
        _storeTrialEligibility[id] = eligibility.status ==
            IntroEligibilityStatus.introEligibilityStatusEligible;
      });
      _notify();
    } catch (e) {
      _log('Trial eligibility check failed: $e');
    }
  }

  Future<void> refreshCustomerInfo({bool force = false}) async {
    if (!_initialized) return;
    try {
      if (force) await Purchases.invalidateCustomerInfoCache();
      final info = await Purchases.getCustomerInfo();
      await _applyCustomerInfo(info);
    } catch (e) {
      _log('refreshCustomerInfo failed (keeping last known state): $e');
    }
  }

  Future<void> _applyCustomerInfo(CustomerInfo info) async {
    _customerInfo = info;
    final entitlement = info.entitlements.active[config.entitlementId];

    var anonymous = true;
    String? userId;
    try {
      anonymous = await Purchases.isAnonymous;
      userId = await Purchases.appUserID;
    } catch (_) {}

    _status = SubscriptionStatus(
      appUserId: userId ?? info.originalAppUserId,
      isAnonymous: anonymous,
      entitlement: entitlement,
      managementUrl: info.managementURL,
      isLifetime: _detectLifetime(entitlement),
    );
    _customerInfoResolved = true;

    if (!_statusController.isClosed) _statusController.add(_status);
    _notify();

    final changed = _status.signature != _lastSignature;
    _lastSignature = _status.signature;
    if (changed && onStatusChanged != null) {
      try {
        await onStatusChanged!(_status);
      } catch (e) {
        _log('onStatusChanged callback failed (non-fatal): $e');
      }
    }
  }

  bool _detectLifetime(EntitlementInfo? e) {
    if (e == null) return false;
    if (e.expirationDate == null) return true;
    final id = e.productIdentifier;
    return config.lifetimeProductIds.contains(id) ||
        id.toLowerCase().contains('lifetime');
  }

  /// Exact plan match. iOS: ids are equal. Google: package id is
  /// "subscriptionId:basePlanId", the entitlement has them separately.
  bool _entitlementMatchesPackage(Package package) {
    final e = _status.entitlement;
    if (e == null) return false;
    final packageId = package.storeProduct.identifier;
    if (packageId == e.productIdentifier) return true;
    final planId = e.productPlanIdentifier;
    if (planId != null && planId.isNotEmpty) {
      return packageId == '${e.productIdentifier}:$planId';
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Purchasing
  // ═══════════════════════════════════════════════════════════════════════

  /// Single entry point for a "Continue / Subscribe" button.
  ///
  /// * No subscription → fresh purchase (free trial applied automatically
  ///   by the store if the user is eligible).
  /// * Active subscription + different subscription plan → plan change
  ///   (Android proration handled; iOS handled by the subscription group).
  /// * Lifetime → one-time purchase.
  ///
  /// Navigate to a success screen ONLY when `outcome.isSuccess`.
  Future<PurchaseOutcome> purchase(Package package) async {
    if (_purchaseLock || isBusy) {
      return const PurchaseOutcome(PurchaseOutcomeStatus.failed,
          message: 'Another purchase is in progress.');
    }
    _purchaseLock = true;
    try {
      final blocked = _blockReason(package);
      if (blocked != null) {
        _setError(blocked);
        return PurchaseOutcome(PurchaseOutcomeStatus.alreadyOwned,
            message: blocked);
      }
      if (isPremium && !isLifetimePackage(package)) {
        return await _changePlan(package);
      }
      return await _buy(package);
    } finally {
      _purchaseLock = false;
    }
  }

  /// Convenience helpers.
  Future<PurchaseOutcome> purchaseMonthly() => _purchaseType(PackageType.monthly);
  Future<PurchaseOutcome> purchaseAnnual() => _purchaseType(PackageType.annual);
  Future<PurchaseOutcome> purchaseLifetime() =>
      _purchaseType(PackageType.lifetime);

  Future<PurchaseOutcome> _purchaseType(PackageType type) async {
    final p = packageOfType(type);
    if (p == null) {
      const msg = 'This plan is not available.';
      _setError(msg);
      return const PurchaseOutcome(PurchaseOutcomeStatus.notAvailable,
          message: msg);
    }
    return purchase(p);
  }

  String? _blockReason(Package package) {
    if (isLifetime) {
      return 'You already have Lifetime access, so there is nothing more to buy.';
    }
    if (isPremium && _entitlementMatchesPackage(package)) {
      return 'You are already subscribed to this plan.';
    }
    return null;
  }

  Future<PurchaseOutcome> _buy(
      Package package, {
        GoogleProductChangeInfo? changeInfo,
        BusyAction action = BusyAction.purchasing,
      }) async {
    final productId = package.storeProduct.identifier;
    final trialBefore = trialFor(package) != null;

    _busy = action;
    _errorMessage = null;
    _notify();
    analytics.purchaseStarted(productId);

    try {
      // purchasePackage lets the store pick the best offer: the free trial is
      // applied automatically when the user is eligible.
      final result = await Purchases.purchasePackage(
        package,
        googleProductChangeInfo: changeInfo,
      );
      await _applyCustomerInfo(result.customerInfo);

      if (!isPremium) {
        const msg =
            'Purchase completed but premium is not active yet. Check that the '
            'product is attached to the entitlement in RevenueCat.';
        _log(msg);
        _errorMessage = msg;
        return const PurchaseOutcome(PurchaseOutcomeStatus.failed, message: msg);
      }

      if (trialBefore && _status.isInTrial) analytics.trialStarted(productId);
      analytics.purchaseCompleted(productId, wasTrial: _status.isInTrial);
      return const PurchaseOutcome(PurchaseOutcomeStatus.success);
    } on PlatformException catch (e) {
      return await _handlePurchaseError(e, productId);
    } catch (e) {
      _log('purchase failed: $e');
      const msg = 'Purchase failed. Please try again.';
      _errorMessage = msg;
      analytics.purchaseFailed(productId, 'unknown');
      return const PurchaseOutcome(PurchaseOutcomeStatus.failed, message: msg);
    } finally {
      _busy = BusyAction.none;
      _notify();
    }
  }

  Future<PurchaseOutcome> _handlePurchaseError(
      PlatformException e,
      String productId,
      ) async {
    final code = PurchasesErrorHelper.getErrorCode(e);
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        analytics.purchaseCancelled(productId);
        return const PurchaseOutcome(PurchaseOutcomeStatus.cancelled);
      case PurchasesErrorCode.paymentPendingError:
        final msg = _messageFor(e, fallback: 'Purchase pending.');
        _errorMessage = msg;
        return PurchaseOutcome(PurchaseOutcomeStatus.pending, message: msg);
      case PurchasesErrorCode.productAlreadyPurchasedError:
        await refreshCustomerInfo(force: true);
        return isPremium
            ? const PurchaseOutcome(PurchaseOutcomeStatus.success)
            : const PurchaseOutcome(PurchaseOutcomeStatus.alreadyOwned);
      default:
        final msg = _messageFor(e, fallback: 'Purchase failed. Please try again.');
        _errorMessage = msg;
        analytics.purchaseFailed(productId, code.name);
        return PurchaseOutcome(PurchaseOutcomeStatus.failed,
            message: msg, errorCode: code.name);
    }
  }

  // ── Plan change (Monthly ⇄ Annual) ─────────────────────────────────────

  static const Map<PackageType, int> _planRank = {
    PackageType.weekly: 1,
    PackageType.monthly: 2,
    PackageType.twoMonth: 3,
    PackageType.threeMonth: 4,
    PackageType.sixMonth: 5,
    PackageType.annual: 6,
    PackageType.lifetime: 7,
  };

  /// Upgrade → immediate with time proration. Downgrade (e.g. Annual →
  /// Monthly) → deferred to the next renewal so the user keeps what they paid.
  GoogleProrationMode _prorationFor(Package newPackage) {
    final currentRank = _planRank[activePlanType] ?? 0;
    final newRank = _planRank[newPackage.packageType] ?? 0;
    return newRank < currentRank
        ? GoogleProrationMode.deferred
        : GoogleProrationMode.immediateWithTimeProration;
  }

  Future<PurchaseOutcome> _changePlan(Package newPackage) async {
    _busy = BusyAction.changingPlan;
    _errorMessage = null;
    _notify();

    try {
      // Server-fresh entitlement first: a stale cache could route the
      // purchase through "product change" when Play has no token to prorate.
      await refreshCustomerInfo(force: true);

      final blocked = _blockReason(newPackage);
      if (blocked != null) {
        _errorMessage = blocked;
        return PurchaseOutcome(PurchaseOutcomeStatus.alreadyOwned,
            message: blocked);
      }

      final fromProductId = _status.productId;
      if (!isPremium || fromProductId == null) {
        return await _buy(newPackage);
      }

      final isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final outcome = await _buy(
        newPackage,
        action: BusyAction.changingPlan,
        changeInfo: isAndroid
            ? GoogleProductChangeInfo(
          fromProductId,
          prorationMode: _prorationFor(newPackage),
        )
            : null,
      );

      if (outcome.isSuccess) {
        analytics.planChanged(
          fromProductId: fromProductId,
          toProductId: newPackage.storeProduct.identifier,
        );
        return outcome;
      }

      // Play can't find a token to prorate against (stale/foreign entitlement):
      // retry once as a fresh purchase.
      final stale = outcome.errorCode ==
          PurchasesErrorCode.purchaseInvalidError.name &&
          (outcome.message?.contains("Couldn't find existing purchase") ??
              false);
      if (stale) {
        _log('Stale purchase token for product change; retrying as fresh buy');
        return await _buy(newPackage);
      }
      return outcome;
    } finally {
      _busy = BusyAction.none;
      _notify();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Restore / sync
  // ═══════════════════════════════════════════════════════════════════════

  /// "Restore Purchases" button. Returns true when an active entitlement
  /// exists afterwards; [errorMessage] explains when it doesn't.
  Future<bool> restorePurchases() async {
    if (_purchaseLock || isBusy) return false;
    _purchaseLock = true;
    _busy = BusyAction.restoring;
    _errorMessage = null;
    _notify();
    try {
      final info = await Purchases.restorePurchases();
      await _applyCustomerInfo(info);
      analytics.restoreCompleted(foundActiveSubscription: isPremium);
      if (!isPremium) {
        _errorMessage = 'No previous purchase found for this account.';
      }
      return isPremium;
    } on PlatformException catch (e) {
      _errorMessage =
          _messageFor(e, fallback: 'Restore failed. Please try again.');
      return false;
    } catch (e) {
      _log('restore failed: $e');
      _errorMessage = 'Restore failed. Please try again.';
      return false;
    } finally {
      _busy = BusyAction.none;
      _purchaseLock = false;
      _notify();
    }
  }

  /// Re-send the device's store receipts to RevenueCat without changing the
  /// user (useful after a migration or if purchases seem missing).
  Future<void> syncPurchases() async {
    try {
      await Purchases.syncPurchases();
      await refreshCustomerInfo(force: true);
    } catch (e) {
      _log('syncPurchases failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Manage / cancel (stores don't allow in-app cancellation)
  // ═══════════════════════════════════════════════════════════════════════

  /// Opens the native Play Store / App Store subscription page.
  Future<bool> openManageSubscription() async {
    _errorMessage = null;
    _awaitingReturnFromStore = true; // onAppResumed does the server-fresh refresh
    final opened = await _openStorePage();
    if (!opened) _awaitingReturnFromStore = false;
    return opened;
  }

  /// "Cancel subscription" button: sends the user to the store page where
  /// they turn auto-renew off. Access continues until `status.expirationDate`
  /// and [willRenew] updates through the listener.
  Future<bool> cancelSubscription() async {
    if (!isPremium) {
      _setError('No active subscription to cancel.');
      return false;
    }
    if (isLifetime) {
      _setError('Lifetime access is a one-time purchase and has nothing to cancel.');
      return false;
    }
    return openManageSubscription();
  }

  Future<String?> _resolveManagementUrl() async {
    if (_status.managementUrl != null) return _status.managementUrl;
    try {
      final info = await Purchases.getCustomerInfo();
      if (info.managementURL != null) return info.managementURL;
    } catch (_) {}

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final pkg = config.androidPackageName;
        final base = 'https://play.google.com/store/account/subscriptions';
        return pkg == null ? base : '$base?package=$pkg';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'https://apps.apple.com/account/subscriptions';
      default:
        return null;
    }
  }

  Future<bool> _openStorePage() async {
    final url = await _resolveManagementUrl();
    if (url == null) {
      _setError('Could not open subscription settings.');
      return false;
    }
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) _setError('Could not open subscription settings.');
      return launched;
    } catch (_) {
      _setError('Could not open subscription settings.');
      return false;
    }
  }

  /// iOS only: Apple's offer-code redemption sheet.
  Future<void> redeemOfferCode() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await Purchases.presentCodeRedemptionSheet();
      _awaitingReturnFromStore = true;
    } catch (e) {
      _log('presentCodeRedemptionSheet failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RevenueCat Paywalls (the paywall you design in the dashboard)
  // ═══════════════════════════════════════════════════════════════════════

  /// Shows the dashboard-designed paywall. Purchase, restore and the Terms /
  /// Privacy buttons are all handled by the paywall itself.
  Future<PaywallResult> presentPaywall({bool displayCloseButton = true}) async {
    analytics.paywallViewed();
    final result = await RevenueCatUI.presentPaywall(
      offering: _offering,
      displayCloseButton: displayCloseButton,
    );
    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await refreshCustomerInfo(force: true);
    }
    return result;
  }

  /// Shows the paywall only if the user does NOT have the entitlement.
  Future<PaywallResult> presentPaywallIfNeeded({
    bool displayCloseButton = true,
  }) async {
    if (isPremium) return PaywallResult.notPresented;
    analytics.paywallViewed();
    final result = await RevenueCatUI.presentPaywallIfNeeded(
      config.entitlementId,
      offering: _offering,
      displayCloseButton: displayCloseButton,
    );
    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await refreshCustomerInfo(force: true);
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Error mapping
  // ═══════════════════════════════════════════════════════════════════════

  String _messageFor(PlatformException e, {required String fallback}) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    switch (code) {
      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        return 'Network error. Check your connection and try again.';
      case PurchasesErrorCode.storeProblemError:
        return 'The app store is having issues right now. Please try again shortly.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are disabled on this device (parental controls or restrictions).';
      case PurchasesErrorCode.purchaseInvalidError:
        return e.message ?? 'This purchase could not be validated. Please try again.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'This plan is not currently available for purchase.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already own this plan.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'This purchase is already linked to another account.';
      case PurchasesErrorCode.invalidCredentialsError:
        return 'App configuration error. Please update the app or contact support.';
      case PurchasesErrorCode.insufficientPermissionsError:
        return "You don't have permission to make purchases on this device.";
      case PurchasesErrorCode.paymentPendingError:
        return 'Your purchase is pending approval and will unlock automatically once confirmed.';
      default:
        return e.message ?? fallback;
    }
  }
}