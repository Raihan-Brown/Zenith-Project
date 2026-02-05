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
      } else {
        // Token expired atau tidak ada
        await logout();
      }
    } catch (e) {
      state = AuthState(isAuthenticated: false);
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      // [FIX 3.1] Endpoint yang benar sesuai router user.py
      final response = await _apiClient.client.get('/users/me');
      
      final user = UserModel.fromJson(response.data);
      
      state = AuthState(
        isAuthenticated: true,
        user: user,
        isLoading: false
      );
    } catch (e) {
      print("ERROR FETCH USER: $e");
      state = state.copyWith(isLoading: false, error: "Gagal memuat data user.");
    }
  }

  Future<void> login(String nis, String password, BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // [FIX 3.2] Ganti FormData menjadi UrlEncoded Form agar diterima FastAPI
      final response = await _apiClient.client.post(
        '/auth/login',
        data: {
          'username': nis, 
          'password': password
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType, // Wajib untuk OAuth2PasswordRequestForm
        ),
      );

      final token = response.data['access_token'];
      if (token == null) throw Exception("Token tidak ditemukan di response");
      
      await _storage.write(key: 'jwt_token', value: token);
      
      // Ambil profile setelah token tersimpan
      await _fetchUserProfile();
      
      if (state.user != null) {
        final role = state.user!.role;
        
        if (!context.mounted) return;

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
        msg = "Format data salah. Pastikan menggunakan Form UrlEncoded.";
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