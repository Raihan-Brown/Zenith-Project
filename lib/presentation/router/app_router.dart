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
      
      // PERBAIKAN: Ambil role dari user (karena authState.role mungkin ga ada di versi baru)
      final userRole = authState.user?.role; 

      // Case A: Belum Login -> Tendang ke /login
      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // Case B: Udah Login tapi masih di halaman Login -> Arahkan sesuai Role
      if (isLoggingIn && isAuthenticated) {
        return userRole == 'ADMIN' ? '/admin' : '/dashboard';
      }

      // Case C: User biasa coba akses halaman Admin -> Balikin ke Dashboard
      if (state.uri.toString().startsWith('/admin') && userRole != 'ADMIN') {
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
      // Nanti tambah route QR scanner disini
    ],
  );
});