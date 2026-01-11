//// lib/core/utils/validators.dart
class Validators {
  static String? validateNIS(String? value) {
    if (value == null || value.isEmpty) return 'NIS is required';
    if (value.length < 5) return 'NIS must be at least 5 characters';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validatePoints(String? value) {
    if (value == null || value.isEmpty) return 'Points required';
    final points = int.tryParse(value);
    if (points == null || points <= 0) return 'Invalid amount';
    return null;
  }
}