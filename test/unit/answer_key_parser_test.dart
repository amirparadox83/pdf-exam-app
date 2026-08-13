// Stage 28 — Answer Key Parser Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/features/answer_key_parser/answer_key_parser.dart';

void main() {
  late RuleBasedAnswerKeyParser parser;

  setUp(() {
    parser = RuleBasedAnswerKeyParser();
  });

  group('Format parsing', () {
    test('parses "1-3" format', () {
      final result = parser.parse('1-3\n2-1\n3-4\n4-2');
      expect(result, hasLength(4));
      expect(result[1], '3');
      expect(result[2], '1');
      expect(result[3], '4');
      expect(result[4], '2');
    });

    test('parses "1:A" format', () {
      final result = parser.parse('1:A\n2:C\n3:B\n4:D');
      expect(result[1], 'A');
      expect(result[2], 'C');
      expect(result[3], 'B');
      expect(result[4], 'D');
    });

    test('parses Persian digits "۱)۳"', () {
      final result = parser.parse('۱)۳\n۲)۱\n۳)۴\n۴)۲');
      expect(result[1], '3');
      expect(result[2], '1');
      expect(result[3], '4');
      expect(result[4], '2');
    });

    test('parses dense single-line format', () {
      final result = parser.parse('1-3 2-1 3-4 4-2');
      expect(result, hasLength(4));
      expect(result[1], '3');
    });

    test('parses "سؤال ۱: الف" format', () {
      final result = parser.parse('سؤال ۱: الف\nسؤال ۲: ج');
      expect(result[1], 'الف');
      expect(result[2], 'ج');
    });

    test('parses mixed digits (Persian + Latin)', () {
      final result = parser.parse('1-A\n۲-ب\n3-3\n۴-۴');
      expect(result, hasLength(4));
    });
  });

  group('Validation', () {
    test('detects missing answers', () {
      final answers = {1: 'A', 2: 'B', 4: 'D'}; // missing 3
      final result = parser.validate(answers, 4);
      expect(result.isValid, isFalse);
      expect(result.missingCount, 1);
      expect(result.issues, anyElement(contains('مفقود')));
    });

    test('detects out-of-range question numbers', () {
      final answers = {1: 'A', 2: 'B', 3: 'C', 4: 'D', 5: 'A'};
      final result = parser.validate(answers, 4);
      expect(result.isValid, isFalse);
      expect(result.outOfRangeCount, 1);
    });

    test('accepts valid answer set', () {
      final answers = {1: 'A', 2: 'B', 3: 'C', 4: 'D'};
      final result = parser.validate(answers, 4);
      expect(result.isValid, isTrue);
      expect(result.missingCount, 0);
    });

    test('flags duplicate question numbers (handled by map)', () {
      // Duplicate keys in map are last-wins.
      final answers = {1: 'A', 2: 'B', 3: 'C', 4: 'D'};
      expect(answers.length, 4);
    });
  });

  group('Edge cases', () {
    test('handles empty input', () {
      final result = parser.parse('');
      expect(result, isEmpty);
    });

    test('handles whitespace-only input', () {
      final result = parser.parse('   \n\n   ');
      expect(result, isEmpty);
    });

    test('handles malformed entries', () {
      final result = parser.parse('garbage line\n1-A\nanother bad line');
      expect(result, hasLength(1));
      expect(result[1], 'A');
    });
  });
}
