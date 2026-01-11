//// lib/data/datasources/api_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class ApiRemoteDataSource {
  final Dio dio;

  ApiRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> login(String nis, String password) async {
    try {
      final response = await dio.post(ApiConstants.loginEndpoint, data: {
        'username': nis,
        'password': password,
      });
      return response.data; // Expected { "access_token": "...", "user": {...} }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Login failed');
    }
  }

  Future<UserModel> fetchUserProfile() async {
    try {
      // Assuming there's a profile endpoint or we decode token
      // For this example, we'll assume the backend returns user data on a generic GET
      // In real implementation, this might be /auth/me
      final response = await dio.get('/auth/me'); 
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch profile');
    }
  }
}