import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../../data/models/leaderboard_model.dart';

// Provider ini akan otomatis memanggil API saat UI membutuhkannya
final leaderboardProvider = FutureProvider<List<LeaderboardModel>>((ref) async {
  final storage = const FlutterSecureStorage();
  final apiClient = ApiClient(storage); // Client kita otomatis inject token
  
  // Panggil fungsi yang tadi kita buat di Datasource
  // Kita akses datasource lewat properti .client di apiClient sebenarnya bisa,
  // tapi biar rapi kita bungkus manual atau panggil manual.
  // Cara cepat (shortcut) pakai dio langsung dari apiClient:
  
  try {
    final response = await apiClient.client.get('/users/leaderboard');
    List<dynamic> data = response.data;
    return data.map((json) => LeaderboardModel.fromJson(json)).toList();
  } catch (e) {
    throw Exception("Gagal memuat leaderboard");
  }
});