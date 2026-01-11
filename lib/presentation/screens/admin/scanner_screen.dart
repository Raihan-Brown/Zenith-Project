import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Ini package scanner
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import core
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

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        final qrCode = barcode.rawValue!;
        
        try {
          // HIT API Backend
          final storage = const FlutterSecureStorage();
          final apiClient = ApiClient(storage);
          
          final response = await apiClient.client.post('/qr/scan', data: {
            "qr_token": qrCode 
          });
          
          if (mounted) {
            _showResultDialog(
              success: true, 
              title: "Berhasil!", 
              message: "User: ${response.data['user']}\nPoin: -${response.data['points_redeemed']}"
            );
          }

        } on DioException catch (e) {
          if (mounted) {
             _showResultDialog(
              success: false, 
              title: "Gagal", 
              message: e.response?.data['detail'] ?? "Terjadi kesalahan"
            );
          }
        }
        break; 
      }
    }
  }

  Future<void> _showResultDialog({required bool success, required String title, required String message}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: success ? Colors.green : Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle : Icons.error, size: 60, color: success ? Colors.green : Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false); // Reset biar bisa scan lagi
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR User")),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _onDetect,
        overlay: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 4),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(50),
        ),
      ),
    );
  }
}