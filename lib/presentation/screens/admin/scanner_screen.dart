import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Package scanner
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import core untuk akses ApiClient
import '../../../core/network/api_client.dart';

class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen> {
  bool _isProcessing = false;
  // Controller scanner
  MobileScannerController cameraController = MobileScannerController();

  // Logika saat QR terdeteksi
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // Mencegah double scan (spam)

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        final qrCode = barcode.rawValue!;

        try {
          // 1. Inisialisasi Storage
          final storage = const FlutterSecureStorage();
          
          // 2. AMBIL TOKEN MANUAL
          // Key 'jwt_token' harus sama dengan yang ada di auth_provider.dart saat login
          String? token = await storage.read(key: 'jwt_token'); 

          if (token == null) {
             throw DioException(
               requestOptions: RequestOptions(path: '/qr/scan'),
               error: "Token tidak ditemukan, silakan login ulang.",
               type: DioExceptionType.unknown
             );
          }

          // 3. Setup Client & Request dengan Header Eksplisit
          // Kita pakai apiClient untuk Base URL, tapi header kita paksa timpa
          final apiClient = ApiClient(storage); 
          
          final response = await apiClient.client.post(
            '/qr/scan', 
            data: {
              "qr_token": qrCode 
            },
            // 4. PAKSA HEADER AUTHORIZATION DI SINI
            // Ini memastikan token pasti terkirim ke backend
            options: Options(
              headers: {
                "Authorization": "Bearer $token",
                "Accept": "application/json",
              }
            )
          );
          
          if (mounted) {
            _showResultDialog(
              success: true, 
              title: "Berhasil!", 
              message: "User: ${response.data['user']}\nPoin: -${response.data['points_redeemed']}"
            );
          }

        } on DioException catch (e) {
          // Debugging: Print error response biar tau kenapa di terminal
          print("Error Scan: ${e.response?.statusCode} - ${e.response?.data}");
          
          String errorMessage = "Gagal memproses QR Code";

          if (e.response != null) {
            final data = e.response?.data;
            if (data is Map && data['detail'] != null) {
              errorMessage = data['detail'].toString(); // Pesan dari backend (misal: "QR Expired")
            } else if (e.response?.statusCode == 422) {
              errorMessage = "Format QR tidak valid.";
            } else if (e.response?.statusCode == 401) {
              errorMessage = "Sesi Admin habis. Login ulang.";
            }
          } else if (e.type == DioExceptionType.unknown && e.error != null) {
             errorMessage = e.error.toString(); // Error token null tadi
          }

          if (mounted) {
             _showResultDialog(
              success: false, 
              title: "Gagal", 
              message: errorMessage
            );
          }
        } catch (e) {
           // Handle error lain (misal storage error)
           if (mounted) {
             _showResultDialog(success: false, title: "Error Aplikasi", message: e.toString());
           }
        }
        break; // Stop loop setelah barcode pertama ditemukan
      }
    }
  }

  // Dialog Hasil Scan
  Future<void> _showResultDialog({required bool success, required String title, required String message}) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // User wajib tekan tombol
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: success ? Colors.green : Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle : Icons.cancel, size: 60, color: success ? Colors.green : Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Delay sedikit sebelum kamera aktif lagi agar tidak langsung scan ulang
              Future.delayed(const Duration(seconds: 1), () {
                 if (mounted) setState(() => _isProcessing = false); 
              });
            },
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR User"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _onDetect,
        overlay: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 4),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(50),
          child: const Center(
            child: Text(
              "Arahkan ke QR Code",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [
                Shadow(blurRadius: 10, color: Colors.black, offset: Offset(0, 2))
              ]),
            ),
          ),
        ),
      ),
    );
  }
}