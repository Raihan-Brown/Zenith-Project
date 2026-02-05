import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/user_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 1. Pantau perubahan state auth
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    // 2. Logic Redirect
    redirect: (context, state) {
      final isLoggingIn = state.uri.toString() == '/login';
      final isAuthenticated = authState.isAuthenticated;
      
      // Ambil role dari user (sudah di-lowercase di UserModel)
      final userRole = authState.user?.role; 

      // Case A: Belum Login -> Tendang ke /login
      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // Case B: Udah Login tapi masih di halaman Login -> Arahkan sesuai Role
      if (isLoggingIn && isAuthenticated) {
        // ⚠️ FIX: Ganti 'ADMIN' jadi 'admin' (huruf kecil)
        return userRole == 'admin' ? '/admin' : '/dashboard';
      }

      // Case C: User biasa coba akses halaman Admin -> Balikin ke Dashboard
      // ⚠️ FIX: Ganti 'ADMIN' jadi 'admin' (huruf kecil)
      if (state.uri.toString().startsWith('/admin') && userRole != 'admin') {
        return '/dashboard';
      }

      return null; // Tidak ada redirect
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const UserDashboard(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});