import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- IMPORT HALAMAN-HALAMAN YANG DIBUTUHKAN ---
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/user_dashboard.dart';
import 'presentation/screens/admin/admin_dashboard.dart'; 
import 'core/theme/app_theme.dart'; // Opsional kalau lu punya theme

void main() {
  runApp(const ProviderScope(child: ZenithApp()));
}

class ZenithApp extends StatelessWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenith App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      
      // Route awal
      initialRoute: '/login', 
      
      // Daftar Rute Navigasi
      routes: {
        '/login': (context) => const LoginScreen(),
        '/user-dashboard': (context) => const UserDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}