import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../data/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient;

  AuthNotifier() : super(AuthState()) {
    _apiClient = ApiClient(_storage);
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null && !JwtDecoder.isExpired(token)) {
        await _fetchUserProfile();
      }
    } catch (e) {
      state = AuthState(isAuthenticated: false);
    }
  }

  // Fungsi Fetch Profile yang lebih kebal
  Future<void> _fetchUserProfile() async {
    try {
      final response = await _apiClient.client.get('/users/me');
      
      // Langsung parsing pakai Model yang baru
      final user = UserModel.fromJson(response.data);
      
      state = AuthState(
        isAuthenticated: true,
        user: user,
        isLoading: false
      );
    } catch (e) {
      print("ERROR FETCH USER: $e");
      // Kalau gagal fetch user, anggap sesi habis/error, jangan logout paksa tapi kasih tau
      state = state.copyWith(isLoading: false, error: "Gagal memuat data user.");
    }
  }

  Future<void> login(String nis, String password, BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 1. Request Login ke Backend (Format Form Data)
      final response = await _apiClient.client.post(
        '/auth/login',
        data: FormData.fromMap({
          'username': nis, 
          'password': password
        }), 
      );

      // 2. Simpan Token
      final token = response.data['access_token'];
      if (token == null) throw Exception("Token tidak ditemukan di response");
      
      await _storage.write(key: 'jwt_token', value: token);
      
      // 3. Ambil Data User Profile SEBELUM pindah halaman
      await _fetchUserProfile();
      
      // 4. Cek apakah user berhasil dimuat?
      if (state.user != null) {
        final role = state.user!.role;
        
        if (!context.mounted) return;

        // Routing berdasarkan Role
        if (role == 'admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/user-dashboard', (route) => false);
        }
      } else {
        throw Exception("Gagal memuat profil user setelah login.");
      }
      
    } on DioException catch (e) {
      String msg = "Terjadi kesalahan koneksi";
      if (e.response?.statusCode == 401) {
        msg = "NIS atau Password salah";
      } else if (e.response?.statusCode == 404) {
        msg = "Endpoint login tidak ditemukan";
      } else if (e.response?.statusCode == 422) {
        msg = "Format data salah (Validation Error)";
      }
      
      state = state.copyWith(isLoading: false, error: msg);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> refreshUserData() async {
    if (state.isAuthenticated) await _fetchUserProfile();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});