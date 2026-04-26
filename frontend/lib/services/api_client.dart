import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refresh = prefs.getString('refresh_token');
          if (refresh != null) {
            try {
              final response = await Dio().post(
                '${ApiConstants.baseUrl}${ApiConstants.tokenRefresh}',
                data: {'refresh': refresh},
              );
              final newAccess = response.data['access'];
              final newRefresh = response.data['refresh'];
              await prefs.setString('access_token', newAccess);
              await prefs.setString('refresh_token', newRefresh);

              error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await dio.fetch(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            } catch (_) {
              await prefs.clear();
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      dio.patch(path, data: data);

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.delete(path, queryParameters: queryParameters);
}
