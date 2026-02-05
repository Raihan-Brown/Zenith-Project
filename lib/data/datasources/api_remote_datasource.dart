import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/leaderboard_model.dart';
import '../models/history_model.dart';
import '../models/report_model.dart';

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

  Future<List<LeaderboardModel>> fetchLeaderboard() async {
    try {
      final response = await dio.get('/users/leaderboard');
      
      // API mengembalikan List, jadi kita map ke Model
      List<dynamic> data = response.data;
      return data.map((json) => LeaderboardModel.fromJson(json)).toList();
    } catch (e) {
      // Jika error, kembalikan list kosong agar UI tidak crash
      print("Error fetching leaderboard: $e");
      return [];
    }
  }

  Future<List<HistoryModel>> fetchUserHistory() async {
    try {
      final response = await dio.get('/users/history');
      
      List<dynamic> data = response.data;
      return data.map((json) => HistoryModel.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching history: $e");
      return []; // Return kosong kalau error, biar gak crash
    }
  }

  Future<List<ReportModel>> fetchAdminReports() async {
    try {
      final response = await dio.get('/qr/reports');
      
      List<dynamic> data = response.data;
      return data.map((json) => ReportModel.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching reports: $e");
      return []; 
    }
  }

  Future<List<UserModel>> fetchAllUsers() async {
    try {
      final response = await dio.get('/users/'); // Endpoint baru
      List<dynamic> data = response.data;
      return data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  // [BARU] Hapus user
  Future<void> deleteUser(String userId) async {
    try {
      await dio.delete('/users/$userId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Gagal menghapus user");
    }
  }
}