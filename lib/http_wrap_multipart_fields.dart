part of 'http_wrap.dart';

/// Converts a multipart leaf value to the string form expected by
/// `http.MultipartRequest.fields`.
///
/// Scalars are converted directly, `DateTime` uses ISO-8601, and other object
/// values fall back to JSON encoding when possible.
String _serializeMultipartFieldValue(dynamic value) {
  // Handle scalar values with direct conversion.
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  if (value is DateTime) return value.toIso8601String();

  // Encode structured leaf values as JSON when supported.
  try {
    return jsonEncode(value);
  } catch (_) {
    // Use a safe fallback for values that cannot be JSON-encoded.
    return value.toString();
  }
}

/// Flattens nested request fields into bracketed keys for
/// multipart form submission.
///
/// Example: `{ "items": ["a"] }` becomes `{ "items[0]": "a" }`.
///
/// Empty lists are omitted because multipart form fields cannot represent an
/// explicit empty array value.
Map<String, String> _buildMultipartFields(Map<String, dynamic>? fields) {
  // Initialize output map and short-circuit when nothing was provided.
  final requestFields = <String, String>{};
  if (fields == null || fields.isEmpty) return requestFields;

  // Seed stack with top-level fields for iterative depth-first traversal.
  final pending = [
    for (final entry in fields.entries) (key: entry.key, value: entry.value),
  ];

  // Expand list/map nodes into bracketed keys until only leaf values remain.
  while (pending.isNotEmpty) {
    final item = pending.removeLast();
    final key = item.key;
    final value = item.value;

    // Drop nulls to avoid sending meaningless form fields.
    if (value == null) continue;

    // Expand list elements as `key[index]` entries.
    if (value is List) {
      if (value.isEmpty) {
        // Multipart cannot represent an explicit empty array value.
        continue;
      }

      for (var i = value.length - 1; i >= 0; i--) {
        pending.add((key: '$key[$i]', value: value[i]));
      }
      continue;
    }

    // Expand map entries as `key[childKey]` entries.
    if (value is Map) {
      final entries = value.entries.toList(growable: false);
      for (var i = entries.length - 1; i >= 0; i--) {
        final entry = entries[i];
        pending.add((key: '$key[${entry.key}]', value: entry.value));
      }
      continue;
    }

    // Serialize leaf value and store final multipart field.
    final stringValue = _serializeMultipartFieldValue(value);
    if (stringValue.isEmpty) {
      continue;
    }

    requestFields[key] = stringValue;
  }

  return requestFields;
}
