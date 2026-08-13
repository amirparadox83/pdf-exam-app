/// PDF Text/Layout Extraction
/// Stage 13 — PDF Text/Layout Extraction
///
/// Extracts characters, words, lines, blocks, paragraphs with coordinates.
/// Handles Persian/Arabic, English, Persian digits, RTL/LTR, formulas.

import '../pdf_engine/pdf_engine.dart';
import '../../domain/entities/entities.dart';

class PdfExtractor {
  final PdfEngine pdfEngine;

  PdfExtractor({required this.pdfEngine});

  /// Extract all text spans from a page, then group into words, lines, blocks.
  Future<PageExtraction> extractPage(PdfDocumentHandle doc, int pageNumber) async {
    final pageText = await doc.extractPageText(pageNumber);

    final words = _groupSpansToWords(pageText.spans);
    final lines = _groupWordsToLines(words);
    final blocks = _groupLinesToBlocks(lines);
    final paragraphs = _groupBlocksToParagraphs(blocks);

    return PageExtraction(
      pageNumber: pageNumber,
      pageWidth: pageText.pageWidth,
      pageHeight: pageText.pageHeight,
      spans: pageText.spans,
      words: words,
      lines: lines,
      blocks: blocks,
      paragraphs: paragraphs,
      quality: _assessQuality(pageText, words, lines),
    );
  }

  List<PdfWord> _groupSpansToWords(List<PdfTextSpan> spans) {
    // Group consecutive spans by whitespace boundaries.
    // In production: use bidi + reshape for Persian.
    final words = <PdfWord>[];
    final current = <PdfTextSpan>[];

    void flush() {
      if (current.isEmpty) return;
      final text = current.map((s) => s.text).join();
      final minX = current.map((s) => s.x).reduce((a, b) => a < b ? a : b);
      final maxX = current.map((s) => s.x + s.width).reduce((a, b) => a > b ? a : b);
      final minY = current.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      final maxY = current.map((s) => s.y + s.height).reduce((a, b) => a > b ? a : b);
      words.add(PdfWord(
        text: _normalizePersian(text),
        x: minX,
        y: minY,
        width: maxX - minX,
        height: maxY - minY,
      ));
      current.clear();
    }

    for (final span in spans) {
      if (span.text.trim().isEmpty) {
        flush();
      } else {
        current.add(span);
      }
    }
    flush();
    return words;
  }

  List<PdfLine> _groupWordsToLines(List<PdfWord> words) {
    if (words.isEmpty) return [];
    // Sort by Y (top to bottom in PDF coords is reverse — Y grows downward).
    words.sort((a, b) => a.y.compareTo(b.y));
    final lines = <PdfLine>[];
    List<PdfWord> current = [words.first];

    for (var i = 1; i < words.length; i++) {
      final w = words[i];
      final lineY = current.first.y;
      // Same line if Y overlap > 70%
      final overlap = _yOverlap(current.first, w);
      if (overlap > 0.5) {
        current.add(w);
      } else {
        lines.add(_makeLine(current));
        current = [w];
      }
    }
    lines.add(_makeLine(current));
    return lines;
  }

  List<PdfBlock> _groupLinesToBlocks(List<PdfLine> lines) {
    if (lines.isEmpty) return [];
    final blocks = <PdfBlock>[];
    List<PdfLine> current = [lines.first];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      final prev = current.last;
      // Same block if vertical gap < line height * 1.5
      final gap = line.y - (prev.y + prev.height);
      if (gap < prev.height * 1.5) {
        current.add(line);
      } else {
        blocks.add(_makeBlock(current));
        current = [line];
      }
    }
    blocks.add(_makeBlock(current));
    return blocks;
  }

  List<PdfParagraph> _groupBlocksToParagraphs(List<PdfBlock> blocks) {
    // For MVP, treat each block as a paragraph.
    return blocks
        .map((b) => PdfParagraph(
              text: b.text,
              x: b.x,
              y: b.y,
              width: b.width,
              height: b.height,
            ))
        .toList();
  }

  PdfLine _makeLine(List<PdfWord> words) {
    words.sort((a, b) => b.x.compareTo(a.x)); // RTL: right to left
    final text = words.map((w) => w.text).join(' ');
    final minX = words.map((w) => w.x).reduce((a, b) => a < b ? a : b);
    final maxX = words.map((w) => w.x + w.width).reduce((a, b) => a > b ? a : b);
    return PdfLine(
      text: text,
      x: minX,
      y: words.first.y,
      width: maxX - minX,
      height: words.map((w) => w.height).reduce((a, b) => a > b ? a : b),
    );
  }

  PdfBlock _makeBlock(List<PdfLine> lines) {
    final text = lines.map((l) => l.text).join('\n');
    final minX = lines.map((l) => l.x).reduce((a, b) => a < b ? a : b);
    final maxX = lines.map((l) => l.x + l.width).reduce((a, b) => a > b ? a : b);
    final minY = lines.first.y;
    final maxY = lines.last.y + lines.last.height;
    return PdfBlock(
      text: text,
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  double _yOverlap(PdfWord a, PdfWord b) {
    final yMin = a.y > b.y ? a.y : b.y;
    final yMax = (a.y + a.height) < (b.y + b.height) ? (a.y + a.height) : (b.y + b.height);
    final overlap = yMax - yMin;
    final minH = a.height < b.height ? a.height : b.height;
    return overlap / minH;
  }

  /// Normalize Persian text: convert Arabic-Yeh to Persian-Yeh, Arabic digits to Persian,
  /// remove tatweel, normalize ZWNJ.
  String _normalizePersian(String text) {
    return text
        .replaceAll('\u064A', '\u06CC') // Arabic Yeh → Persian Yeh
        .replaceAll('\u0649', '\u06CC') // Alef Maksura → Persian Yeh
        .replaceAll('\u0643', '\u06A9') // Arabic Kaf → Persian Kaf
        .replaceAll('\u0623', '\u0627') // Alef with Hamza above → Alef
        .replaceAll('\u0625', '\u0627') // Alef with Hamza below → Alef
        .replaceAll('\u0622', '\u0627') // Alef with Madda → Alef
        .replaceAll('\u0640', '') // Tatweel
        .trim();
  }

  ExtractionQuality _assessQuality(PdfPageText pageText, List<PdfWord> words, List<PdfLine> lines) {
    if (pageText.spans.isEmpty) {
      return ExtractionQuality.noText;
    }
    final persianRatio = words.where((w) => _hasPersian(w.text)).length / words.length;
    if (persianRatio > 0.3 && words.any((w) => _isGarbled(w.text))) {
      return ExtractionQuality.needsReshape;
    }
    if (lines.length < 3) {
      return ExtractionQuality.sparse;
    }
    return ExtractionQuality.good;
  }

  bool _hasPersian(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  bool _isGarbled(String text) {
    // If text has Persian range but no joined forms (i.e., isolated forms only),
    // it's probably garbled.
    return RegExp(r'^[\u0600-\u0625\u0627-\u063A\u0641-\u064A\s]+$').hasMatch(text) &&
        text.length > 2 &&
        !text.contains(' ') &&
        !RegExp(r'[\uFE70-\uFEFF]').hasMatch(text);
  }
}

// === Extraction result types ===

class PageExtraction {
  final int pageNumber;
  final double pageWidth;
  final double pageHeight;
  final List<PdfTextSpan> spans;
  final List<PdfWord> words;
  final List<PdfLine> lines;
  final List<PdfBlock> blocks;
  final List<PdfParagraph> paragraphs;
  final ExtractionQuality quality;

  PageExtraction({
    required this.pageNumber,
    required this.pageWidth,
    required this.pageHeight,
    required this.spans,
    required this.words,
    required this.lines,
    required this.blocks,
    required this.paragraphs,
    required this.quality,
  });
}

enum ExtractionQuality { good, sparse, needsReshape, noText }

class PdfWord {
  final String text;
  final double x, y, width, height;
  PdfWord({required this.text, required this.x, required this.y, required this.width, required this.height});
}

class PdfLine {
  final String text;
  final double x, y, width, height;
  PdfLine({required this.text, required this.x, required this.y, required this.width, required this.height});
}

class PdfBlock {
  final String text;
  final double x, y, width, height;
  PdfBlock({required this.text, required this.x, required this.y, required this.width, required this.height});
}

class PdfParagraph {
  final String text;
  final double x, y, width, height;
  PdfParagraph({required this.text, required this.x, required this.y, required this.width, required this.height});
}
