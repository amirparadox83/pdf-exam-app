/// Stage 12 — PDF Test Fixtures
///
/// Generates synthetic PDF test fixtures in various Persian/Arabic/English formats.
/// Each fixture has expected extraction results that tests can compare against.
///
/// These fixtures are generated programmatically to avoid copyright issues.
/// They cover all the edge cases listed in the Stage 12 prompt.

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FixtureGenerator {
  /// Generate all test fixtures into the given directory.
  static Future<void> generateAll(String outputDir) async {
    final dir = Directory(outputDir);
    await dir.create(recursive: true);

    for (final fixture in _fixtures) {
      final bytes = await _buildPdf(fixture);
      final file = File('${dir.path}/${fixture.fileName}');
      await file.writeAsBytes(bytes);

      // Write expected results JSON alongside
      final expectedFile = File('${dir.path}/${fixture.fileName}.expected.json');
      await expectedFile.writeAsString(_expectedJson(fixture));
    }
  }

  static const _fixtures = <PdfFixture>[
    PdfFixture(
      fileName: 'persian_basic.pdf',
      title: 'سؤالات پایه فارسی',
      description: '۴ سؤال چهارگزینه‌ای ساده با اعداد فارسی',
      questions: [
        _FixtureQuestion(
          number: '۱',
          body: 'پایتخت ایران کدام شهر است؟',
          options: ['شیراز', 'تهران', 'اصفهان', 'مشهد'],
          correctOption: 1,
        ),
        _FixtureQuestion(
          number: '۲',
          body: 'طول رودخانه کارون چقدر است؟',
          options: ['۸۰۰ کیلومتر', '۸۵۰ کیلومتر', '۹۵۰ کیلومتر', '۹۰۰ کیلومتر'],
          correctOption: 3,
        ),
      ],
    ),
    PdfFixture(
      fileName: 'persian_letters_options.pdf',
      title: 'سؤالات با گزینه‌های الف/ب/ج/د',
      description: 'سؤالات با برچسب گزینه فارسی',
      questions: [
        _FixtureQuestion(
          number: '۱',
          body: 'فرمول آب چیست؟',
          options: ['H2O', 'CO2', 'NaCl', 'O2'],
          correctOption: 0,
          optionLabels: ['الف', 'ب', 'ج', 'د'],
        ),
      ],
    ),
    PdfFixture(
      fileName: 'multi_line_question.pdf',
      title: 'سؤال چندخطی',
      description: 'سؤال با بدنه چندخطی',
      questions: [
        _FixtureQuestion(
          number: '۱',
          body: 'یک گاز ایده‌آل در حجم ثابت داریم.\nاگر دمای آن را دو برابر کنیم،\nفشار آن چه تغییری می‌کند؟',
          options: ['دو برابر می‌شود', 'نصف می‌شود', 'تغییری نمی‌کند', 'صفر می‌شود'],
          correctOption: 0,
        ),
      ],
    ),
  ];

  static Future<Uint8List> _buildPdf(PdfFixture fixture) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(fixture.title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          for (final q in fixture.questions) ...[
            pw.Text('${q.number}. ${q.body}', style: const pw.TextStyle(fontSize: 13)),
            pw.SizedBox(height: 8),
            for (var i = 0; i < q.options.length; i++) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 20, bottom: 4),
                child: pw.Text('${q.optionLabels?[i] ?? i + 1}) ${q.options[i]}'),
              ),
            ],
            pw.SizedBox(height: 16),
          ],
          pw.SizedBox(height: 30),
          pw.Text('کلید پاسخ:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
            fixture.questions
                .map((q) => '${q.number}-${q.optionLabels?[q.correctOption] ?? q.correctOption + 1}')
                .join('   '),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _expectedJson(PdfFixture fixture) {
    final buf = StringBuffer('{\n');
    buf.writeln('  "fileName": "${fixture.fileName}",');
    buf.writeln('  "title": "${fixture.title}",');
    buf.writeln('  "expectedQuestionCount": ${fixture.questions.length},');
    buf.writeln('  "questions": [');
    for (var i = 0; i < fixture.questions.length; i++) {
      final q = fixture.questions[i];
      buf.writeln('    {');
      buf.writeln('      "number": "${q.number}",');
      buf.writeln('      "body": "${q.body.replaceAll('\n', '\\n')}",');
      buf.writeln('      "options": [${q.options.map((o) => '"$o"').join(', ')}],');
      buf.writeln('      "correctOptionIndex": ${q.correctOption},');
      buf.writeln('      "optionLabels": [${(q.optionLabels ?? ['۱', '۲', '۳', '۴']).map((l) => '"$l"').join(', ')}]');
      buf.write(i == fixture.questions.length - 1 ? '    }\n' : '    },\n');
    }
    buf.writeln('  ]');
    buf.write('}');
    return buf.toString();
  }
}

class PdfFixture {
  final String fileName;
  final String title;
  final String description;
  final List<_FixtureQuestion> questions;

  const PdfFixture({
    required this.fileName,
    required this.title,
    required this.description,
    required this.questions,
  });
}

class _FixtureQuestion {
  final String number;
  final String body;
  final List<String> options;
  final int correctOption;
  final List<String>? optionLabels;

  _FixtureQuestion({
    required this.number,
    required this.body,
    required this.options,
    required this.correctOption,
    this.optionLabels,
  });
}
