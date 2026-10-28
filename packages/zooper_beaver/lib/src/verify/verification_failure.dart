/// Formatted output is not the same program as the input (exit 70).
final class VerificationFailure implements Exception {
  const VerificationFailure(this.stage, this.detail);

  /// The check that failed, e.g. `tokens`, `fingerprint`, `comments`.
  final String stage;
  final String detail;

  @override
  String toString() => 'Verification failed ($stage): $detail';
}
