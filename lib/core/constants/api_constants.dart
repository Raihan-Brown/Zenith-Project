//// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'http://10.158.139.2:8000/'; // Replace with real API
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String leaderboardEndpoint = '/leaderboard';
  static const String generateQrEndpoint = '/qr/generate';
  static const String verifyQrEndpoint = '/qr/verify';
  static const String transactionsEndpoint = '/admin/qr-transactions';
}