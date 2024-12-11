import 'dart:convert';
import 'package:flutter/material.dart';

class JsonPrettifier extends StatelessWidget {
  final dynamic jsonInput;

  const JsonPrettifier({super.key, required this.jsonInput});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SelectableText.rich(
        _formatJson(jsonInput),
      ),
    );
  }

  TextSpan _formatJson(dynamic jsonInput) {
    if (jsonInput is! Map<String, dynamic>?) {
      throw ArgumentError('Input must be a decoded JSON object.');
    }
    const encoder = JsonEncoder.withIndent('    ');
    final jsonString = encoder.convert(jsonInput);
    return _colorizeJson(jsonString);
  }

  TextSpan _colorizeJson(String jsonString) {
    final spans = <TextSpan>[];

    // Regex to identify JSON components:
    // 1. Keys: "key" (followed by :)
    // 2. Strings: "value"
    // 3. Numbers: 123, 12.34
    // 4. Booleans and null: true, false, null
    // 5. Punctuation: {}, [], :, ,
    final regex = RegExp(
        r'(?<key>"[^"]*?")(?=\s*:)|(".*?")|(\b\d+\.?\d*\b)|(\btrue\b|\bfalse\b|\bnull\b)|([{}[\],:])');

    final matches = regex.allMatches(jsonString);
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        // Add plain text before the match
        spans.add(TextSpan(
          text: jsonString.substring(lastMatchEnd, match.start),
          style: const TextStyle(color: Colors.white),
        ));
      }

      final matchedText = match.group(0)!;
      TextStyle style;

      if (match.namedGroup('key') != null) {
        // Keys
        style = const TextStyle(color: Colors.red);
      } else if (match.group(1) != null) {
        // Strings
        style = const TextStyle(color: Colors.green);
      } else if (match.group(2) != null) {
        // Numbers
        style = const TextStyle(color: Colors.blue);
      } else if (match.group(3) != null) {
        // Booleans or null
        style = const TextStyle(color: Colors.orange);
      } else {
        // Punctuation
        style = const TextStyle(color: Colors.grey);
      }

      spans.add(TextSpan(text: matchedText, style: style));
      lastMatchEnd = match.end;
    }

    // Add remaining plain text
    if (lastMatchEnd < jsonString.length) {
      spans.add(TextSpan(
        text: jsonString.substring(lastMatchEnd),
        style: const TextStyle(color: Colors.white),
      ));
    }

    return TextSpan(children: spans);
  }
}
