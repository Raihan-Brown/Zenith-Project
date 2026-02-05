import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../../data/models/user_model.dart';

// Provider untuk List User
final manageUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final storage = const FlutterSecureStorage();
  final apiClient = ApiClient(storage);
  
  try {
    final response = await apiClient.client.get('/users/');
    List<dynamic> data = response.data;
    return data.map((json) => UserModel.fromJson(json)).toList();
  } catch (e) {
    throw Exception("Gagal memuat data user");
  }
});

// Controller untuk aksi Delete (biar UI lebih bersih)
class UserActionController extends StateNotifier<bool> {
  UserActionController() : super(false); // False = idle, True = loading

  Future<void> deleteUser(String userId, WidgetRef ref) async {
    state = true; // Loading mulai
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(storage);

    try {
      await apiClient.client.delete('/users/$userId');
      // Kalau sukses, refresh list user
      ref.refresh(manageUsersProvider);
    } catch (e) {
      rethrow; // Lempar error ke UI biar jadi SnackBar
    } finally {
      state = false; // Loading selesai
    }
  }
}

final userActionProvider = StateNotifierProvider<UserActionController, bool>((ref) {
  return UserActionController();
});