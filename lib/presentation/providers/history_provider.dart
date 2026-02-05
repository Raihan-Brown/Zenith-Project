import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../../data/models/history_model.dart';

final historyProvider = FutureProvider<List<HistoryModel>>((ref) async {
  final storage = const FlutterSecureStorage();
  final apiClient = ApiClient(storage);
  
  // Panggil API lewat client
  try {
    final response = await apiClient.client.get('/users/history');
    List<dynamic> data = response.data;
    return data.map((json) => HistoryModel.fromJson(json)).toList();
  } catch (e) {
    throw Exception("Gagal memuat history");
  }
});