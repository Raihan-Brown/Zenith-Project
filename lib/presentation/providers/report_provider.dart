import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../../data/models/report_model.dart';

final reportProvider = FutureProvider.autoDispose<List<ReportModel>>((ref) async {
  final storage = const FlutterSecureStorage();
  final apiClient = ApiClient(storage);
  
  try {
    final response = await apiClient.client.get('/qr/reports');
    List<dynamic> data = response.data;
    return data.map((json) => ReportModel.fromJson(json)).toList();
  } catch (e) {
    throw Exception("Gagal memuat laporan admin");
  }
});