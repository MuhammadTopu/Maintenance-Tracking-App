import 'package:dio/dio.dart';
import 'package:maintenance_genie/app/controller/auth_event_controller.dart';
import 'package:maintenance_genie/core/constants/api_end_points.dart';
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import 'package:maintenance_genie/data/models/auth_response_model.dart';

enum RefreshStatus {
  success,

  rejected,

  failed,

  noSession,
}

class SessionRefreshResult {
  const SessionRefreshResult(this.status, {this.role});

  final RefreshStatus status;

  final String? role;

  bool get isSuccess => status == RefreshStatus.success;
}

class SessionRefreshService {
  SessionRefreshService._();

  static final SessionRefreshService instance = SessionRefreshService._();

  final Dio _dio = Dio(
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

  Future<SessionRefreshResult>? _inFlight;

  Future<SessionRefreshResult> refresh() {
    return _inFlight ??= _run().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> endSession() async {
    await TokenStorageService.instance.clearAll();
    AuthEventController.instance.fireSessionExpired();
  }

  Future<SessionRefreshResult> _run() async {
    final storage = TokenStorageService.instance;
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const SessionRefreshResult(RefreshStatus.noSession);
    }

    try {
      Log.info('Refreshing access token');
      final response = await _dio.post(
        ApiEndPoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const SessionRefreshResult(RefreshStatus.rejected);
      }

      final auth = AuthResponseModel.fromJson(data);
      if (auth.token.isEmpty) {
        return const SessionRefreshResult(RefreshStatus.rejected);
      }

      await storage.saveTokens(
        accessToken: auth.token,
        refreshToken: auth.refreshToken,
      );

      final user = data['user'];
      final role = user is Map ? user['role']?.toString() : null;
      return SessionRefreshResult(RefreshStatus.success, role: role);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      Log.error('Token refresh failed: status=$code type=${e.type}');
      if (code == 400 || code == 401 || code == 403) {
        return const SessionRefreshResult(RefreshStatus.rejected);
      }
      return const SessionRefreshResult(RefreshStatus.failed);
    } catch (e) {
      Log.error('Token refresh error: $e');
      return const SessionRefreshResult(RefreshStatus.failed);
    }
  }
}