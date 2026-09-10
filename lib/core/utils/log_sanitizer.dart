/// Strips emails, passwords, and tokens before a message is sent to Crashlytics.
class LogSanitizer {
  LogSanitizer._();

  static const String redacted = '[redacted]';
  static const int maxLength = 500;

  static final RegExp _email = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
  static final RegExp _secretAssignment = RegExp(
    r'(password|passwd|pwd|token|fcmtoken|apikey|authorization|bearer)\s*[:=]\s*\S+',
    caseSensitive: false,
  );
  static final RegExp _longSecret = RegExp(r'[A-Za-z0-9_-]{40,}');

  static String scrub(String input) {
    var value = input.replaceAll(_email, redacted);
    value = value.replaceAll(_secretAssignment, redacted);
    value = value.replaceAll(_longSecret, redacted);
    if (value.length > maxLength) {
      return value.substring(0, maxLength);
    }
    return value;
  }
}
