import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // Biar font global ke-load

// --- IMPORT HALAMAN ---
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/user_dashboard.dart';
import 'presentation/screens/admin/admin_dashboard.dart';
import 'presentation/screens/splash/splash_screen.dart'; // Import Splash baru

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        // Set Font Global jadi Poppins/Google Fonts biar modern
        textTheme: GoogleFonts.poppinsTextTheme(), 
      ),
      
      // [UBAH INI] Route awal jadi splash
      initialRoute: '/splash', 
      
      routes: {
        '/splash': (context) => const SplashScreen(), // Daftarkan splash
        '/login': (context) => const LoginScreen(),
        '/user-dashboard': (context) => const UserDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}