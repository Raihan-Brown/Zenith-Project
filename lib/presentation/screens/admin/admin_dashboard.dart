import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Provider & Pages
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'scanner_screen.dart';
import 'admin_reports_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data admin yang sedang login
    final authState = ref.watch(authProvider);
    final adminName = authState.user?.name ?? "Admin";

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background lebih bersih
      appBar: AppBar(
        title: const Text(
          "ZENITH ADMIN", 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              // Confirm Logout
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Keluar dari panel admin?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx), 
                      child: const Text("Batal")
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authProvider.notifier).logout();
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      child: const Text("Keluar", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. WELCOME HEADER
            Text(
              "Selamat Datang, \n$adminName! 🛡️",
              style: const TextStyle(
                fontSize: 26, 
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50), // Dark Blue Grey
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Control Center & Monitoring",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            
            const SizedBox(height: 24),

            // 2. HERO CARD (Control Status)
            _buildAdminHeroCard(),

            const SizedBox(height: 32),
            
            // 3. MENU LABEL
            const Text(
              "Main Menu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 4. GRID MENU (3 Fitur Utama)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  title: "Scan QR",
                  subtitle: "Validasi Redeem",
                  icon: Icons.qr_code_scanner,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScannerScreen())),
                ),
                _buildMenuCard(
                  context,
                  title: "Laporan",
                  subtitle: "Cek Transaksi",
                  icon: Icons.bar_chart,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
                ),
                _buildMenuCard(
                  context,
                  title: "Users",
                  subtitle: "Kelola Pengguna",
                  icon: Icons.people_alt,
                  color: Colors.green, // Dibuat lebar (span 2) nanti di bawah
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                  isWide: false, 
                ),
                // Bisa tambah menu lain di sini nanti
                 _buildMenuCard(
                  context,
                  title: "Settings",
                  subtitle: "App Config",
                  icon: Icons.settings,
                  color: Colors.grey,
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildAdminHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Gradient Biru Tua - Ungu (Kesan Tech/Admin)
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C5364).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "System Status",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                "Online & Secure",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12, 
                  color: Colors.grey[600]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}