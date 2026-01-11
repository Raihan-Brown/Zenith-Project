import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Buat input angka only
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';

class RedeemQrWidget extends ConsumerStatefulWidget {
  const RedeemQrWidget({super.key});

  @override
  ConsumerState<RedeemQrWidget> createState() => _RedeemQrWidgetState();
}

class _RedeemQrWidgetState extends ConsumerState<RedeemQrWidget> {
  final _pointsController = TextEditingController(); // 1. Controller buat input
  bool _isLoading = false;
  String? _qrToken;
  int _timeLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _pointsController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateQr() async {
    // 2. Ambil nilai dari input, ubah ke integer
    final String inputStr = _pointsController.text.trim();
    final int requestPoints = int.tryParse(inputStr) ?? 0;

    // 3. Validasi lokal biar gak ngirim 0 atau kosong
    if (requestPoints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah poin yang valid (minimal 1)")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(storage);

    try {
      // 4. Debugging: Print apa yang dikirim (Cek di terminal VS Code)
      print("Mengirim request redeem: $requestPoints poin");

      final response = await apiClient.client.post('/qr/generate', data: {
        "points": requestPoints // Kirim INT, bukan String
      });

      setState(() {
        _qrToken = response.data['qr_token']; 
        _timeLeft = 60; 
        _isLoading = false;
      });

      _startTimer();
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Tampilkan pesan error dari backend (misal: Poin tidak cukup)
        final errorMsg = e.response?.data['detail'] ?? "Gagal generate QR";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        setState(() => _qrToken = null); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userPoints = authState.user?.points ?? 0;
    
    // Cek realtime apakah input valid
    final currentInput = int.tryParse(_pointsController.text) ?? 0;
    final bool canRedeem = currentInput > 0 && currentInput <= userPoints;

    return Container(
      padding: const EdgeInsets.all(24),
      height: 600, // Agak tinggiin biar muat keyboard
      width: double.infinity,
      child: SingleChildScrollView( // Biar bisa discroll pas keyboard muncul
        child: Column(
          children: [
            const Text("Redeem Poin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Saldo kamu: $userPoints Pts", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_qrToken != null)
              Column(
                children: [
                  QrImageView(
                    data: _qrToken!,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Token: $_qrToken", // Tampilkan token buat debug (opsional)
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    "Valid selama: $_timeLeft detik",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _qrToken = null),
                    child: const Text("Tutup / Buat Baru"),
                  )
                ],
              )
            else
              Column(
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.teal),
                  const SizedBox(height: 20),
                  
                  // INPUT FIELD ANGKANYA DISINI
                  TextField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Cuma boleh angka
                    decoration: const InputDecoration(
                      labelText: "Jumlah Poin",
                      hintText: "Contoh: 50",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    onChanged: (val) => setState(() {}), // Refresh button state
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: canRedeem ? _generateQr : null, // Disable kalau 0 atau saldo kurang
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white
                      ),
                      child: const Text("Generate QR"),
                    ),
                  ),

                  if (currentInput > userPoints)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text("Saldo tidak cukup!", style: TextStyle(color: Colors.red)),
                    )
                ],
              )
          ],
        ),
      ),
    );
  }
}