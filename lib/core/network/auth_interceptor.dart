import 'dart:async';

import 'package:dio/dio.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import '../../data/models/auth_response_model.dart';
import '../../app/controller/auth_event_controller.dart';
import '../constants/api_end_points.dart';
import '../helper/logger.dart';

enum _RefreshResult { success, rejected, failed }

/// Attaches the access token and transparently refreshes it on 401.
/// A plain [Interceptor] is used (not a QueuedInterceptor) because the retry
/// goes back through the same Dio, and a queued interceptor would deadlock.
/// Concurrent 401s share one refresh call.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio})
      : _dio = dio,
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiEndPoints.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  final Dio _dio;

  /// No interceptors, so the refresh call can never trigger a refresh.
  final Dio _refreshDio;

  static const String _retriedKey = 'auth_retried';

  /// 401 on these means wrong credentials/OTP, not an expired session.
  static const Set<String> _noRefreshPaths = {
    ApiEndPoints.login,
    ApiEndPoints.register1,
    ApiEndPoints.verifyOtp,
    ApiEndPoints.register3,
    ApiEndPoints.forgetPassword,
    ApiEndPoints.resetPasswordOtp,
    ApiEndPoints.resetPassword,
    ApiEndPoints.refreshToken,
  };

  Future<_RefreshResult>? _refreshFuture;

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await TokenStorageService.instance.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final ro = err.requestOptions;

    final shouldSkip = err.response?.statusCode != 401 ||
        ro.extra[_retriedKey] == true ||
        _noRefreshPaths.contains(ro.path);
    if (shouldSkip) {
      return handler.next(err);
    }

    final storage = TokenStorageService.instance;
    final currentAccess = await storage.getToken();
    final refreshToken = await storage.getRefreshToken();
    final hasAccess = currentAccess != null && currentAccess.isNotEmpty;
    final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;

    // Already logged out (e.g. a queued request failing after session end).
    if (!hasAccess && !hasRefresh) {
      return handler.next(err);
    }

    // Legacy session from before refresh tokens existed: cannot be renewed.
    if (!hasRefresh) {
      await _endSession();
      return handler.next(err);
    }

    // Another request already refreshed while this one was in flight.
    final usedToken = _bearerOf(ro.headers['Authorization']);
    if (hasAccess && usedToken != currentAccess) {
      return _retryAndResolve(err, handler);
    }

    final result = await _refreshOnce(refreshToken);
    switch (result) {
      case _RefreshResult.success:
        return _retryAndResolve(err, handler);
      case _RefreshResult.rejected:
        await _endSession();
        return handler.next(err);
      case _RefreshResult.failed:
      // Network/server problem: keep the session, surface the error.
        return handler.next(err);
    }
  }

  Future<_RefreshResult> _refreshOnce(String refreshToken) {
    return _refreshFuture ??= _doRefresh(refreshToken).whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<_RefreshResult> _doRefresh(String refreshToken) async {
    try {
      Log.info('Refreshing access token');
      final response = await _refreshDio.post(
        ApiEndPoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return _RefreshResult.rejected;

      final auth = AuthResponseModel.fromJson(data);
      if (auth.token.isEmpty) return _RefreshResult.rejected;

      // Rotation: the new refresh token replaces the old one.
      await TokenStorageService.instance.saveTokens(
        accessToken: auth.token,
        refreshToken: auth.refreshToken,
      );
      return _RefreshResult.success;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      Log.error('Token refresh failed: status=$code type=${e.type}');
      if (code == 400 || code == 401 || code == 403) {
        return _RefreshResult.rejected;
      }
      return _RefreshResult.failed;
    } catch (e) {
      Log.error('Token refresh error: $e');
      return _RefreshResult.failed;
    }
  }

  Future<void> _retryAndResolve(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    try {
      final ro = err.requestOptions;
      final data = ro.data;
      final response = await _dio.fetch<dynamic>(
        ro.copyWith(
          // A FormData stream can only be read once, so clone it.
          data: data is FormData ? data.clone() : data,
          extra: {...ro.extra, _retriedKey: true},
        ),
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _endSession() async {
    await TokenStorageService.instance.clearAll();
    AuthEventController.instance.fireSessionExpired();
  }

  String? _bearerOf(dynamic header) {
    final value = header?.toString();
    if (value == null || !value.startsWith('Bearer ')) return null;
    return value.substring(7);
  }
}