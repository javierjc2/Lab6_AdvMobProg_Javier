/// Form validators shared by the sign-up and change-password forms.
class Validators {
  Validators._();

  static String? required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'Please enter your $label' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email address';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email address';
  }

  static String? age(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your age';
    final n = int.tryParse(v.trim());
    if (n == null || n < 1 || n > 120) return 'Enter a valid age (1-120)';
    return null;
  }

  static String? contactNo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your contact number';
    final digits = v.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
      return 'Enter a valid contact number';
    }
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a username';
    if (v.trim().length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[A-Za-z0-9._]+$').hasMatch(v.trim())) {
      return 'Use letters, numbers, "." or "_" only';
    }
    return null;
  }

  /// Min 8 chars with an uppercase letter, a lowercase letter, a digit and
  /// a special character.
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a password';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add a lowercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add a number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Add a special character';
    return null;
  }
}
