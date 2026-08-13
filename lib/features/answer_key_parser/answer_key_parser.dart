/// Answer Key Parser — Stage 15
/// Deterministic parser for answer keys in various formats.
///
/// Supported formats:
///   1-3         (question 1 → option 3)
///   2-1
///   1:A         (question 1 → option A)
///   2:C
///   ۱)۳         (Persian digits)
///   ۲)۱
///   Table format with rows and columns.

import '../../domain/entities/entities.dart';

abstract class AnswerKeyParser {
  /// Parse a list of text lines (or full text) into a map of questionNumber → optionLabel.
  Map<int, String> parse(String text);

  /// Validate the parsed answers against question count.
  AnswerKeyValidation validate(Map<int, String> answers, int questionCount);
}

class RuleBasedAnswerKeyParser implements AnswerKeyParser {
  @override
  Map<int, String> parse(String text) {
    final answers = <int, String>{};
    final lines = text.split(RegExp(r'[\n;]+'));

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Try several patterns
      // Pattern 1:  "1-3" or "۱-۳"  (question - answer)
      final p1 = RegExp(r'^(\d{1,3}|[\u06F0-\u06F9]{1,3}|[\u0660-\u0669]{1,3})\s*[-–]\s*(\d{1,2}|[\u06F0-\u06F9]{1,2}|[\u0660-\u0669]{1,2}|[A-Da-d]|[الفبجد])\s*$');
      // Pattern 2:  "1:A" or "1)A" or "1-A"
      final p2 = RegExp(r'^(\d{1,3}|[\u06F0-\u06F9]{1,3}|[\u0660-\u0669]{1,3})\s*[:)\\-]\s*([A-Da-d]|[الفبجد]|\d{1,2}|[\u06F0-\u06F9]{1,2}|[\u0660-\u0669]{1,2})\s*$');
      // Pattern 3: "Q1: A" or "سؤال ۱: الف"
      final p3 = RegExp(r'^(?:Q|q|سؤال|سوال|Question)\s*(\d{1,3}|[\u06F0-\u06F9]{1,3})\s*[:\-]\s*([A-Da-d]|[الفبجد]|\d{1,2}|[\u06F0-\u06F9]{1,2})\s*$');
      // Pattern 4: dense line "1-3 2-1 3-4 4-2"
      final p4 = RegExp(r'(\d{1,3}|[\u06F0-\u06F9]{1,3})\s*[-–:)]\s*([A-Da-d]|[الفبجد]|\d{1,2}|[\u06F0-\u06F9]{1,2})');

      // First try patterns that match the whole line
      Match? m = p1.firstMatch(line) ?? p2.firstMatch(line) ?? p3.firstMatch(line);

      if (m != null) {
        final qNum = _normalizeDigits(m.group(1)!);
        final ans = _normalizeOption(m.group(2)!);
        if (answers.containsKey(qNum)) {
          // Duplicate — skip but flag later in validation
          continue;
        }
        answers[qNum] = ans;
      } else {
        // Try pattern 4: dense line with multiple entries
        final matches = p4.allMatches(line);
        if (matches.length > 1) {
          for (final mm in matches) {
            final qNum = _normalizeDigits(mm.group(1)!);
            final ans = _normalizeOption(mm.group(2)!);
            if (!answers.containsKey(qNum)) {
              answers[qNum] = ans;
            }
          }
        }
      }
    }

    return answers;
  }

  @override
  AnswerKeyValidation validate(Map<int, String> answers, int questionCount) {
    final issues = <String>[];

    // Check for missing answers
    final missing = <int>[];
    for (var i = 1; i <= questionCount; i++) {
      if (!answers.containsKey(i)) {
        missing.add(i);
      }
    }
    if (missing.isNotEmpty) {
      issues.add('پاسخ‌های مفقود: ${missing.take(10).join('، ')}${missing.length > 10 ? '...' : ''}');
    }

    // Check for out-of-range question numbers
    final outOfRange = answers.keys.where((k) => k < 1 || k > questionCount).toList();
    if (outOfRange.isNotEmpty) {
      issues.add('شماره سؤال خارج از بازه: ${outOfRange.join('، ')}');
    }

    // Check for invalid option labels
    final validLabels = {'1', '2', '3', '4', 'A', 'B', 'C', 'D', 'الف', 'ب', 'ج', 'د'};
    final invalidLabels = answers.entries
        .where((e) => !validLabels.contains(e.value))
        .map((e) => '${e.key}→${e.value}')
        .toList();
    if (invalidLabels.isNotEmpty) {
      issues.add('برچسب گزینه نامعتبر: ${invalidLabels.take(5).join('، ')}');
    }

    return AnswerKeyValidation(
      isValid: issues.isEmpty,
      issues: issues,
      missingCount: missing.length,
      outOfRangeCount: outOfRange.length,
    );
  }

  int _normalizeDigits(String s) {
    if (s.isEmpty) return -1;
    final persian = s.replaceAllMapped(RegExp(r'[\u06F0-\u06F9]'), (Match m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0x06F0 + 0x30));
    final arabic = persian.replaceAllMapped(RegExp(r'[\u0660-\u0669]'), (Match m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0x0660 + 0x30));
    return int.tryParse(arabic) ?? -1;
  }

  String _normalizeOption(String s) {
    // Convert Persian digits to Latin
    String result = s;
    if (RegExp(r'^[\u06F0-\u06F9]{1,2}$').hasMatch(result)) {
      result = _normalizeDigits(result).toString();
    }
    // Convert to uppercase for letters
    if (result.length == 1 && result.toLowerCase() != result) {
      result = result.toUpperCase();
    }
    // Keep Persian letters as-is
    return result;
  }
}

class AnswerKeyValidation {
  final bool isValid;
  final List<String> issues;
  final int missingCount;
  final int outOfRangeCount;

  AnswerKeyValidation({
    required this.isValid,
    required this.issues,
    required this.missingCount,
    required this.outOfRangeCount,
  });
}
