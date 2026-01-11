import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nisController = TextEditingController(); // Ganti nama jadi NIS biar sesuai
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nisController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ambil state auth buat cek loading/error
    final authState = ref.watch(authProvider);

    // Listener buat nampilin error via SnackBar kalau ada
    ref.listen(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "ZENITH",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 40),
                
                // Input NIS
                TextFormField(
                  controller: _nisController,
                  decoration: const InputDecoration(
                    labelText: "NIS / Username",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? "NIS tidak boleh kosong" : null,
                ),
                const SizedBox(height: 16),
                
                // Input Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) => value!.isEmpty ? "Password tidak boleh kosong" : null,
                ),
                const SizedBox(height: 24),

                // Tombol Login
                authState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // --- PERBAIKAN UTAMA DISINI ---
                            // Masukkan 'context' sebagai parameter ke-3
                            ref.read(authProvider.notifier).login(
                                  _nisController.text,
                                  _passwordController.text,
                                  context, // <--- INI WAJIB ADA
                                );
                          }
                        },
                        child: const Text("LOGIN", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}