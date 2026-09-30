// Central Pool Client Idempotency Service (Step 5/13)
// PROVENANCE & SEMANTIC DEFINITION:
// - Generates and manages client-side idempotency keys for mutation operations.
// - Ensures retries use the identical idempotency key to prevent duplicate allocations.
// - Server remains authoritative for idempotency tracking and OCC.

import 'dart:math';

class IdempotencyService {
  final Random _random;

  IdempotencyService({Random? random}) : _random = random ?? Random.secure();

  /// Generates a standard UUID v4 string for client idempotency tracking.
  String generateKey({String prefix = 'idem'}) {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    // Set UUID version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set UUID variant (RFC 4122)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hexChars = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final uuid = '${hexChars.substring(0, 8)}-${hexChars.substring(8, 12)}-${hexChars.substring(12, 16)}-${hexChars.substring(16, 20)}-${hexChars.substring(20, 32)}';

    return '$prefix-$uuid';
  }

  /// Generates a deterministic client request identifier.
  String generateClientRequestId(String memberId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(10000).toString().padLeft(4, '0');
    return 'req-${memberId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}-$timestamp-$randomSuffix';
  }
}
