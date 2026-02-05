import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 1. Setup Animasi (Fade In & Zoom Out sedikit)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // 2. Jalankan Cek Login setelah animasi selesai (delay 3 detik)
    Future.delayed(const Duration(seconds: 3), () {
       _checkSession();
    });
  }

  Future<void> _checkSession() async {
    // Panggil fungsi cek login di AuthProvider
    await ref.read(authProvider.notifier).checkLoginStatus();
    final authState = ref.read(authProvider);

    if (!mounted) return;

    // Logika Navigasi
    if (authState.isAuthenticated && authState.user != null) {
      if (authState.user!.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-dashboard');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Aplikasi
                Image.asset(
                  'assets/images/logo.png', 
                  width: 150, 
                  height: 150,
                ),
                const SizedBox(height: 20),
                // Nama Aplikasi
                Text(
                  "ZENITH",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  "Smart Waste Management",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 50),
                // Loading Indicator kecil di bawah
                const CircularProgressIndicator(color: Colors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}