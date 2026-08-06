import 'package:dio/dio.dart';

import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';

import '../../app/controller/auth_event_controller.dart';
import '../constants/api_end_points.dart';
import '../helper/logger.dart';

class Network {
  static final Network _instance = Network._internal();

  factory Network() => _instance;

  late final Dio dio;

  Network._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndPoints.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorageService.instance.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          Log.info('REQUEST');
          Log.debug(
            '${options.method} ${options.uri}\n\nHeaders: ${options.headers}\n\nData: ${options.data}',
          );

          handler.next(options);
        },

        onResponse: (response, handler) {
          Log.info('RESPONSE');
          Log.debug(
            '${response.requestOptions.method} ${response.requestOptions.uri}\n\nStatus: ${response.statusCode}\n\nData: ${response.data}',
          );

          handler.next(response);
        },

        onError: (error, handler) {
          Log.error('''
══════════ API ERROR ══════════
URL         : ${error.requestOptions.uri}
METHOD      : ${error.requestOptions.method}
STATUS CODE : ${error.response?.statusCode}

HEADERS:
${error.requestOptions.headers}

REQUEST:
${error.requestOptions.data}

RESPONSE:
${error.response?.data}

MESSAGE:
${error.message}
═══════════════════════════════
''');

          if (error.response?.statusCode == 401) {
            AuthEventController.instance.fireSessionExpired();
          }

          handler.next(error);
        },
      ),
    );
  }
}