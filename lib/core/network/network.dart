import 'package:dio/dio.dart';

import '../constants/api_end_points.dart';
import '../helper/logger.dart';
import 'auth_interceptor.dart';

class Network {
  static final Network _instance = Network._internal();

  factory Network() => _instance;

  late final Dio dio;

  Network._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndPoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio: dio));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
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
          handler.next(error);
        },
      ),
    );
  }
}