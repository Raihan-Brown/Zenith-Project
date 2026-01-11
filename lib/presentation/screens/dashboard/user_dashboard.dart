// lib/presentation/screens/dashboard/user_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:zenith_app/presentation/screens/qr/reedem_qr_widget.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class UserDashboard extends ConsumerWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data user dari state
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      
      appBar: AppBar(
        title: const Text("ZENITH", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        // --- FITUR 1: TOMBOL LOGOUT ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Keluar",
            onPressed: () {
              // Tampilkan dialog konfirmasi biar ga kepencet
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Konfirmasi"),
                  content: const Text("Yakin mau keluar akun?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Tutup dialog
                        ref.read(authProvider.notifier).logout(); // Panggil fungsi logout provider
                        Navigator.pushReplacementNamed(context, '/login'); // Lempar ke login
                      },
                      child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshUserData();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- KARTU STATUS (POINTS) ---
            _buildStatusCard(user?.points ?? 0),

            const SizedBox(height: 24),
            
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 12),

            // --- TOMBOL-TOMBOL (ROW) ---
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
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- FITUR 2: LEADERBOARD ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Top Green Heroes 🏆",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {}, // Nanti arahkan ke halaman full leaderboard
                  child: const Text("Lihat Semua"),
                )
              ],
            ),
            
            const SizedBox(height: 8),

            // List Leaderboard (Hardcode dulu biar nongol UI-nya)
            // Nanti lu ganti pakai ListView.builder dari data API
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildLeaderboardItem(1, "Raihan", "1,250 Pts", Colors.amber),
                  const Divider(height: 1),
                  _buildLeaderboardItem(2, "Siti Aminah", "980 Pts", Colors.grey),
                  const Divider(height: 1),
                  _buildLeaderboardItem(3, "Budi Santoso", "850 Pts", Colors.brown),
                ],
              ),
            ),
            
            const SizedBox(height: 20), // Spacer bawah
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildStatusCard(int points) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.secondaryColor, Color(0xFF34495E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Your Impact", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(
                "$points Pts",
                style: const TextStyle(color: AppTheme.accentColor, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Gold Tier 🥇", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
          CircularPercentIndicator(
            radius: 45.0,
            lineWidth: 8.0,
            percent: 0.7,
            center: const Icon(Icons.eco, size: 35, color: AppTheme.primaryColor),
            progressColor: AppTheme.primaryColor,
            backgroundColor: Colors.white10,
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }

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
      subtitle: const Text("Student Class A"),
      trailing: Text(points, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
    );
  }

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