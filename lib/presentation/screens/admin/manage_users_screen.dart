import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/manage_users_provider.dart';
import '../../../core/theme/app_theme.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(manageUsersProvider);
    final isDeleting = ref.watch(userActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Pengguna"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      // Menampilkan Loading Overlay kalau lagi proses hapus
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => ref.refresh(manageUsersProvider),
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text("Tidak ada user terdaftar."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final user = users[index];
                    final bool isAdmin = user.role.toLowerCase() == 'admin';

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.orange : AppTheme.primaryColor,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${user.nis} • ${user.points} Pts"),
                        trailing: isAdmin 
                          ? null // Jangan kasih tombol delete ke sesama admin (opsional)
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, ref, user.id, user.name),
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          if (isDeleting)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus User?"),
        content: Text("Yakin ingin menghapus data $userName? Aksi ini tidak bisa dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog dulu
              try {
                await ref.read(userActionProvider.notifier).deleteUser(userId, ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User berhasil dihapus"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}