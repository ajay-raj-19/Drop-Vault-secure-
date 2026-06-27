import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Converts any string ID into a valid and deterministic UUID v4 format.
///
/// If the input string is already a valid UUID, it is returned in lowercase.
/// Otherwise, it performs an MD5 hash on the string and formats the result
/// as a standard 8-4-4-4-12 UUID string.
String toUuid(String id) {
  final uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  if (uuidRegex.hasMatch(id)) {
    return id.toLowerCase();
  }

  // Create a deterministic hash from the input string
  final bytes = utf8.encode(id);
  final hash = md5.convert(bytes).toString(); // 32 hex characters

  // Re-format the hash string into standard UUID structure:
  // xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  return '${hash.substring(0, 8)}-'
      '${hash.substring(8, 12)}-'
      '${hash.substring(12, 16)}-'
      '${hash.substring(16, 20)}-'
      '${hash.substring(20, 32)}';
}
