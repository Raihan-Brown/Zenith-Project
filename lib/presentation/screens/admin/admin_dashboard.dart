// lib/presentation/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Pastikan path import ini sesuai dengan lokasi file auth_provider lu
import '../../providers/auth_provider.dart'; 
// Ini import ke file yang baru aja lu bikin di Langkah 1
import 'scanner_screen.dart'; 

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kita ambil fungsi logout dari provider
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              // Fungsi Logout
              authNotifier.logout();
              // Pindah ke halaman Login dan hapus semua history page sebelumnya
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // --- MENU 1: SCAN QR ---
          _AdminMenuCard(
            icon: Icons.qr_code_scanner,
            label: "Scan QR",
            color: Colors.orange,
            onTap: () {
              // Navigasi ke Scanner Page
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const AdminScannerScreen())
              );
            },
          ),
          
          // --- MENU 2: REPORTS (Dummy) ---
          _AdminMenuCard(
            icon: Icons.bar_chart,
            label: "Reports",
            color: Colors.blue,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Fitur Report Coming Soon!")),
               );
            },
          ),

          // --- MENU 3: MANAGE USERS (Dummy) ---
          _AdminMenuCard(
            icon: Icons.people,
            label: "Users",
            color: Colors.green,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Fitur Manage Users Coming Soon!")),
               );
            },
          ),
        ],
      ),
    );
  }
}

// Widget kecil buat tombol kotak-kotak
class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}