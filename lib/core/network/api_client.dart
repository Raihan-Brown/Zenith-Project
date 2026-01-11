// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient(this._storage) : _dio = Dio(BaseOptions(
    baseUrl: 'http://10.158.139.2:8000/', // Replace with actual IP
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expired: logic to clear storage & trigger logout handled in Repo
          await _storage.delete(key: 'jwt_token');
        }
        return handler.next(e);
      },
    ));
  }

  Dio get client => _dio;
}