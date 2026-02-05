import 'dart:ui'; // WAJIB ADA untuk efek Glassmorphism (ImageFilter)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// Import Provider & Model
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart'; 
import '../../../data/models/user_model.dart';

// Import Halaman & Widget Lain
import '../../../core/theme/app_theme.dart';
import '../qr/reedem_qr_widget.dart';
import '../../providers/history_screen.dart'; 

class UserDashboard extends ConsumerWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil data User & Leaderboard dari Provider
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text("ZENITH", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              // Logika Logout
              ref.read(authProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          )
        ],
      ),
      
      // --- BODY ---
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data user & leaderboard berbarengan
          await ref.read(authProvider.notifier).refreshUserData();
          return ref.refresh(leaderboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. HEADER PROFIL (Nama & Avatar)
            _buildProfileHeader(user),

            // 2. KARTU STATUS POIN (Update: Pakai Gradient, Tanpa Gambar)
            _buildStatusCard(user?.points ?? 0),

            const SizedBox(height: 24),
            
            // 3. QUICK ACTIONS (Tombol Menu)
            const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: "Redeem QR",
                    icon: Icons.qr_code_scanner,
                    iconColor: AppTheme.primaryColor,
                    onTap: () => _showRedeemSheet(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: "History",
                    icon: Icons.history,
                    iconColor: Colors.orange,
                    onTap: () {
                      // Navigasi ke Halaman History
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. LEADERBOARD SECTION (Real Data API)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Top Green Heroes 🏆",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => ref.refresh(leaderboardProvider),
                  child: const Text("Refresh"),
                )
              ],
            ),
            
            const SizedBox(height: 8),

            // List Leaderboard
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: leaderboardAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: Text("Gagal memuat: $err", style: const TextStyle(color: Colors.red))),
                ),
                data: (leaders) {
                  if (leaders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text("Belum ada data.")),
                    );
                  }
                  
                  return Column(
                    children: List.generate(leaders.length, (index) {
                      final item = leaders[index];
                      // Warna badge untuk Juara 1, 2, 3
                      Color badgeColor = Colors.grey;
                      if (index == 0) badgeColor = Colors.amber;
                      if (index == 1) badgeColor = Colors.blueGrey;
                      if (index == 2) badgeColor = Colors.brown;

                      return Column(
                        children: [
                          _buildLeaderboardItem(index + 1, item.name, "${item.points} Pts", badgeColor),
                          if (index < leaders.length - 1) const Divider(height: 1),
                        ],
                      );
                    }),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  // Header Profil
  Widget _buildProfileHeader(UserModel? user) {
    String initial = "?";
    if (user != null && user.name.isNotEmpty) {
      initial = user.name[0].toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: AppTheme.primaryColor
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Halo, ${user?.name ?? 'Guest'}! 👋",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's save the earth today!",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Kartu Status (Clean Gradient Style)
  Widget _buildStatusCard(int points) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // [UPDATE] Ganti Image jadi Gradient Hijau-Teal yang fresh
        gradient: const LinearGradient(
          colors: [
            Color(0xFF11998E), // Hijau Gelap Modern
            Color(0xFF38EF7D)  // Hijau Terang (Mint)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998E).withOpacity(0.4), // Shadow mengikuti warna dominan
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // Pola Lingkaran Putih Transparan (Biar gak polos banget)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Efek Kaca (Blur) - Tetap kita pake biar teks-nya "pop up"
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur halus
                child: Container(
                  color: Colors.white.withOpacity(0.05), // Layer tipis banget
                ),
              ),
            ),
          ),
          
          // Konten Utama
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Your Impact",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$points Pts",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        shadows: [
                            Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(0, 2))
                        ]
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3))
                      ),
                      child: const Text("Gold Tier 🥇", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                CircularPercentIndicator(
                  radius: 45.0,
                  lineWidth: 8.0,
                  percent: 0.7, 
                  center: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.eco, size: 30, color: Color(0xFF11998E)), // Icon ikut warna tema
                  ),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white24,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tombol Aksi
  Widget _buildActionButton(BuildContext context, {
    required String label, required IconData icon, required Color iconColor, required VoidCallback onTap
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 100,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))
            ],
          ),
        ),
      ),
    );
  }

  // Item List Leaderboard
  Widget _buildLeaderboardItem(int rank, String name, String points, Color badgeColor) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: badgeColor.withOpacity(0.1),
        child: Text(
          "#$rank",
          style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("User Zenith"),
      trailing: Text(points, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
    );
  }

  // Bottom Sheet Redeem
  void _showRedeemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: RedeemQrWidget(),
        ),
      ),
    );
  }
}