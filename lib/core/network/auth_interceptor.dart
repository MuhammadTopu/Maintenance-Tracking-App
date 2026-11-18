import 'package:dio/dio.dart';
import 'package:maintenance_genie/core/services/auth/session_refresh_service.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import '../constants/api_end_points.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio}) : _dio = dio;

  final Dio _dio;

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

    final shouldSkip =
        err.response?.statusCode != 401 ||
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
      await SessionRefreshService.instance.endSession();
      return handler.next(err);
    }

    // Another request already refreshed while this one was in flight.
    final usedToken = _bearerOf(ro.headers['Authorization']);
    if (hasAccess && usedToken != currentAccess) {
      return _retryAndResolve(err, handler);
    }

    final result = await SessionRefreshService.instance.refresh();
    switch (result.status) {
      case RefreshStatus.success:
        return _retryAndResolve(err, handler);
      case RefreshStatus.rejected:
        await SessionRefreshService.instance.endSession();
        return handler.next(err);
      case RefreshStatus.failed:
      case RefreshStatus.noSession:
      // Network/server problem (or logged out meanwhile): keep the session
      // as it is and surface the error.
        return handler.next(err);
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

  String? _bearerOf(dynamic header) {
    final value = header?.toString();
    if (value == null || !value.startsWith('Bearer ')) return null;
    return value.substring(7);
  }
}