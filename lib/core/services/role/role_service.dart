import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/core/services/auth/session_refresh_service.dart';
import 'package:maintenance_genie/core/services/role/user_role.dart';
import 'package:maintenance_genie/core/services/subscription/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleService extends ChangeNotifier {
  RoleService({
    required SubscriptionService subscription,
    SessionRefreshService? refresher,
  }) : _subscription = subscription,
        _refresher = refresher ?? SessionRefreshService.instance {
    _lastRole = role;
    _lastResolved = isResolved;
    _statusSub = _subscription.statusStream.listen(_onStatus);
  }

  static const String _prefsKey = 'role_sync_key';

  /// Attempts to see the new role on the backend (webhook lag).
  static const List<Duration> _retryDelays = <Duration>[
    Duration.zero,
    Duration(seconds: 3),
    Duration(seconds: 8),
  ];

  final SubscriptionService _subscription;
  final SessionRefreshService _refresher;
  StreamSubscription<SubscriptionStatus>? _statusSub;

  UserRole _lastRole = UserRole.normal;
  bool _lastResolved = false;

  /// Sync key of the last identified status we handled. Null = nobody is
  /// identified (logged out / RevenueCat still anonymous).
  String? _handledKey;

  UserRole? _backendRole;
  Future<bool>? _inFlight;
  bool _dirty = false;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// The user's role, straight from the RevenueCat entitlement.
  UserRole get role =>
      _subscription.isPremium ? UserRole.premium : UserRole.normal;

  bool get isPremium => role.isPremium;

  /// RevenueCat has answered at least once. Until then `role` is "normal" only
  /// because nothing is known yet, so show a neutral state instead of a lock.
  bool get isResolved => _subscription.hasResolved;

  /// The role the backend reported on the last successful refresh (null until
  /// the first one, or when the response had none).
  UserRole? get backendRole => _backendRole;

  /// A token refresh for the role is running.
  bool get isSyncing => _inFlight != null;

  bool can(AppFeature feature) => role.index >= feature.minimumRole.index;

  /// Refreshes the tokens now and waits until the backend shows the same role
  /// as RevenueCat. Use it when a premium endpoint answers 403
  /// `premiumRequired` while RevenueCat says premium, then retry the request
  /// once if this returns true. Returns false when nobody is logged in.
  Future<bool> forceSync() {
    if (_handledKey == null) return Future<bool>.value(false);
    return _sync();
  }

  // ---------------------------------------------------------------------------
  // RevenueCat status -> role / sync
  // ---------------------------------------------------------------------------

  void _onStatus(SubscriptionStatus status) {
    if (_disposed) return;
    _emitIfChanged();
    unawaited(_handle(status));
  }

  Future<void> _handle(SubscriptionStatus status) async {
    try {
      if (status.isAnonymous || status.appUserId == null) {
        await _onLoggedOut();
        return;
      }

      final key = _keyFor(status);
      if (key == _handledKey) return; // nothing that matters changed

      final isFirst = _handledKey == null;
      _handledKey = key;

      // First identified status of this session: the backend was already told
      // about exactly this state last time, nothing to do.
      if (isFirst && await _readStoredKey() == key) return;

      await _sync();
    } catch (e) {
      Log.error('RoleService: could not handle status: $e');
    }
  }

  Future<void> _onLoggedOut() async {
    final wasLoggedIn = _handledKey != null;
    _handledKey = null;
    _backendRole = null;
    _dirty = false;

    // At every app start RevenueCat is anonymous for a moment: that is not a
    // logout, so only forget the stored state after a real one.
    if (!wasLoggedIn) return;
    await _clearStoredKey();
    _safeNotify();
  }

  /// What the backend cares about. A change means "refresh the tokens":
  /// purchase / restore (premium + product), plan change (product), renewal
  /// (expiry date), expiry (premium off), another account (user id).
  String _keyFor(SubscriptionStatus status) {
    final expiry = status.expirationDate?.toUtc().toIso8601String() ?? '';
    return '${status.appUserId}|${status.isPremium ? 'premium' : 'normal'}|'
        '${status.productId ?? ''}|$expiry';
  }

  // ---------------------------------------------------------------------------
  // Backend sync
  // ---------------------------------------------------------------------------

  /// Single flight. A change that arrives while a sync is running marks it
  /// dirty and the sync runs once more, so the latest state always wins.
  Future<bool> _sync() {
    final running = _inFlight;
    if (running != null) {
      _dirty = true;
      return running;
    }

    final future = _syncLoop().whenComplete(() {
      _inFlight = null;
      _safeNotify();
    });
    _inFlight = future;
    _safeNotify();
    return future;
  }

  Future<bool> _syncLoop() async {
    var ok = false;
    do {
      _dirty = false;
      ok = await _syncUntilMatch();
    } while (_dirty && !_disposed && _handledKey != null);
    return ok;
  }

  Future<bool> _syncUntilMatch() async {
    for (final delay in _retryDelays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (_disposed || _handledKey == null) return false;

      final result = await _refresher.refresh();

      switch (result.status) {
        case RefreshStatus.noSession:
          return false;

        case RefreshStatus.rejected:
        // Refresh token refused: same rule as the interceptor, log out.
          await _refresher.endSession();
          return false;

        case RefreshStatus.failed:
          continue; // network problem: try again

        case RefreshStatus.success:
          final reported = result.role == null
              ? null
              : UserRole.fromApi(result.role);
          _backendRole = reported;

          // No role in the response: tokens are fresh, nothing to compare.
          if (reported == null || reported == role) {
            await _storeKey(_keyFor(_subscription.status));
            return true;
          }
          Log.info(
            'RoleService: backend says ${reported.apiValue}, RevenueCat says '
                '${role.apiValue}. Waiting for the webhook, retrying.',
          );
      }
    }

    // Not stored, so the next app start tries again.
    Log.error(
      'RoleService: backend role (${_backendRole?.apiValue}) still differs '
          'from RevenueCat (${role.apiValue}).',
    );
    return false;
  }

  // ---------------------------------------------------------------------------
  // Stored sync state
  // ---------------------------------------------------------------------------

  Future<String?> _readStoredKey() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_prefsKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeKey(String key) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_prefsKey, key);
    } catch (e) {
      Log.error('RoleService: could not store sync state: $e');
    }
  }

  Future<void> _clearStoredKey() async {
    try {
      await (await SharedPreferences.getInstance()).remove(_prefsKey);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  void _emitIfChanged() {
    final currentRole = role;
    final resolved = isResolved;
    if (currentRole == _lastRole && resolved == _lastResolved) return;
    _lastRole = currentRole;
    _lastResolved = resolved;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_statusSub?.cancel());
    _statusSub = null;
    super.dispose();
  }
}