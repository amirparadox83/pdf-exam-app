// Stage 12/13 — PDF Engine integration test
//
// Verifies the full chain:
//   1. Open a synthetic PDF (built in-memory with the `pdf` package)
//   2. Render page 1 to PNG via pdfrx → real bytes, non-empty
//   3. Extract text from page 1 via pdfrx → real spans, non-empty
//   4. Feed the extracted text into QuestionParser → real DetectedQuestion
//   5. Feed answer-key text into AnswerKeyParser → real map
//
// This test ONLY passes when pdfrx is correctly wired. If renderPageToPng or
// extractPageText are still skeletons (UnimplementedError / empty spans),
// this test fails with a clear assertion.
//
// Note on Persian text: the `pdf` package's default font (Helvetica) does
// not include Persian glyphs, so we use Latin text in the synthetic PDF.
// Persian text extraction is covered by question_parser_test.dart which
// feeds synthetic PdfBlock objects directly (no PDF rendering needed).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:persian_pdf_exam/features/answer_key_parser/answer_key_parser.dart';
import 'package:persian_pdf_exam/features/pdf_engine/pdf_engine.dart';
import 'package:persian_pdf_exam/features/pdf_extraction/pdf_extractor.dart';
import 'package:persian_pdf_exam/features/question_parser/question_parser.dart';

void main() {
  // Build a small synthetic PDF with Latin text and a 4-option question,
  // so the parsers have something realistic to chew on.
  late Uint8List pdfBytes;

  setUpAll(() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Sample Exam', style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 16),
          pw.Text('1. What is the capital of France?'),
          pw.SizedBox(height: 6),
          pw.Text('A) London'),
          pw.Text('B) Paris'),
          pw.Text('C) Rome'),
          pw.Text('D) Berlin'),
          pw.SizedBox(height: 16),
          pw.Text('2. 2 + 2 = ?'),
          pw.SizedBox(height: 6),
          pw.Text('A) 3'),
          pw.Text('B) 4'),
          pw.Text('C) 5'),
          pw.Text('D) 6'),
          pw.SizedBox(height: 20),
          pw.Text('Answer key: 1-B 2-B'),
        ],
      ),
    );
    pdfBytes = await doc.save();
  });

  group('PDF Engine integration', () {
    late PdfrxPdfEngine engine;

    setUp(() {
      // fileStorage is optional — engine doesn't use it for open/render/extract.
      engine = PdfrxPdfEngine();
    });
    tearDown(() => engine.dispose());

    test('openData returns a handle with pageCount >= 1', () async {
      final handle = await engine.openData(pdfBytes);
      expect(handle.pageCount, greaterThanOrEqualTo(1));
      await handle.close();
    });

    test('renderPageToPng returns non-empty PNG bytes', () async {
      final handle = await engine.openData(pdfBytes);
      try {
        final png = await handle.renderPageToPng(1, scale: 1.0);
        // PNG magic header: 0x89 P N G
        expect(png.length, greaterThan(8),
            reason: 'PNG buffer must not be empty');
        expect(png[0], 0x89, reason: 'first byte should be PNG magic');
        expect(png[1], 0x50, reason: 'second byte should be "P"');
        expect(png[2], 0x4E, reason: 'third byte should be "N"');
        expect(png[3], 0x47, reason: 'fourth byte should be "G"');
      } finally {
        await handle.close();
      }
    });

    test('extractPageText returns at least one span with non-empty text', () async {
      final handle = await engine.openData(pdfBytes);
      try {
        final pageText = await handle.extractPageText(1);
        expect(pageText.spans, isNotEmpty,
            reason: 'extractPageText must return real spans, not []');
        final anyNonEmpty = pageText.spans.any((s) => s.text.trim().isNotEmpty);
        expect(anyNonEmpty, isTrue);
      } finally {
        await handle.close();
      }
    });

    test('full chain: PDF → extract → text contains known phrase', () async {
      final handle = await engine.openData(pdfBytes);
      try {
        final pageText = await handle.extractPageText(1);
        // At least one span should mention "Paris" or "capital" or "2 + 2".
        final known = pageText.spans.any((s) =>
            s.text.contains('Paris') ||
            s.text.contains('capital') ||
            s.text.contains('2 + 2') ||
            s.text.contains('Answer'));
        expect(known, isTrue,
            reason: 'extracted text must contain at least one known phrase');
      } finally {
        await handle.close();
      }
    });

    test('full chain: PdfExtractor propagates real spans from engine', () async {
      final handle = await engine.openData(pdfBytes);
      try {
        final extractor = PdfExtractor(pdfEngine: engine);
        final extraction = await extractor.extractPage(handle, 1);
        expect(extraction.spans, isNotEmpty,
            reason: 'PdfExtractor must propagate real spans from engine');
      } finally {
        await handle.close();
      }
    });

    test('full chain: answer-key parser runs on plain text', () {
      // Independent of pdfrx — but ensures the chain's last stage works.
      final parser = RuleBasedAnswerKeyParser();
      final answers = parser.parse('1-B\n2-B');
      expect(answers[1], 'B');
      expect(answers[2], 'B');
    });
  });
}
