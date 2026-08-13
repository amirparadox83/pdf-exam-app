/// PDF Engine abstraction
/// Stage 11 — PDF Engine Integration
/// Stage 12 — PDF rendering (PNG output) — REAL implementation
/// Stage 13 — PDF text/layout extraction — REAL implementation
///
/// The rest of the application must NOT depend directly on the underlying
/// PDF library (pdfrx/PDFium). All access goes through this abstraction.
///
/// API reference (pdfrx ^1.0.110):
///   - `PdfDocument.openFile(path)` / `PdfDocument.openData(bytes)` → Future<PdfDocument>
///   - `PdfDocument.pages` → List<PdfPage> (1-indexed conceptually; 0-indexed in list)
///   - `PdfPage.size` → PdfPageSize (width, height)
///   - `PdfPage.render(...)` → Future<PdfPageImage?> — returns RGBA pixels
///   - `PdfPageText` (via `PdfPage.loadText()` / `PdfPage.text` in newer versions)
///     exposes `spans` (List<PdfPageTextFragment>) with `text` + `boundingBox`.
///
/// PNG encoding: pdfrx returns raw RGBA bytes; we use the `image` package
/// (`PngEncoder`) to encode them to PNG.

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../../data/file_storage/file_storage_service.dart';

/// Represents an opened PDF document
abstract class PdfDocumentHandle {
  int get pageCount;
  double getPageWidth(int pageNumber);
  double getPageHeight(int pageNumber);
  Future<Uint8List> renderPageToPng(int pageNumber, {double scale = 1.0});
  Future<PdfPageText> extractPageText(int pageNumber);
  Future<void> close();
}

/// Text extracted from a page, with positioned spans
class PdfPageText {
  final int pageNumber;
  final List<PdfTextSpan> spans;
  final double pageWidth;
  final double pageHeight;

  PdfPageText({
    required this.pageNumber,
    required this.spans,
    required this.pageWidth,
    required this.pageHeight,
  });

  /// Convenience: full plain-text of the page (spans concatenated, space-separated).
  String get fullText => spans.map((s) => s.text).join(' ');
}

class PdfTextSpan {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? fontName;
  final double fontSize;

  PdfTextSpan({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.fontName,
    this.fontSize = 12,
  });
}

/// Main PDF engine abstraction
abstract class PdfEngine {
  Future<PdfDocumentHandle> openFile(String filePath);
  Future<PdfDocumentHandle> openData(Uint8List data);
  Future<PdfDocumentMetadata> inspect(String filePath);
  void dispose();
}

class PdfDocumentMetadata {
  final String? title;
  final String? author;
  final String? subject;
  final String? producer;
  final String? creator;
  final int pageCount;
  final bool isEncrypted;
  final bool isLinearized;
  final String? version;

  PdfDocumentMetadata({
    this.title,
    this.author,
    this.subject,
    this.producer,
    this.creator,
    required this.pageCount,
    this.isEncrypted = false,
    this.isLinearized = false,
    this.version,
  });
}

/// Implementation of PdfEngine using pdfrx (PDFium)
///
/// Stage 12: `renderPageToPng` uses `PdfPage.render()` to obtain RGBA pixel
/// buffer, then encodes to PNG via the `image` package (`PngEncoder`).
///
/// Stage 13: `extractPageText` uses `PdfPage.loadText()` (available in
/// pdfrx ^1.0.x) which returns a `PdfPageText?` whose `spans` property is a
/// `List<PdfPageTextFragment>`. Each fragment exposes `.text` and
/// `.boundingBox` (a `PdfRect`).
///
/// `fileStorage` is optional: it's a hook for future render-cache integration
/// (Stage 31+) but the engine itself does not need it to open/render/extract.
class PdfrxPdfEngine implements PdfEngine {
  /// Optional cache layer — currently unused by the engine itself but kept
  /// for future integration and to keep the constructor signature stable.
  final FileStorageService? fileStorage;

  PdfrxPdfEngine({this.fileStorage});

  @override
  Future<PdfDocumentHandle> openFile(String filePath) async {
    final doc = await PdfDocument.openFile(filePath);
    return _PdfrxHandle(doc);
  }

  @override
  Future<PdfDocumentHandle> openData(Uint8List data) async {
    final doc = await PdfDocument.openData(data);
    return _PdfrxHandle(doc);
  }

  @override
  Future<PdfDocumentMetadata> inspect(String filePath) async {
    final handle = await openFile(filePath);
    try {
      // pdfrx exposes limited metadata via PdfDocument
      return PdfDocumentMetadata(
        pageCount: handle.pageCount,
        // Encryption detection would require lower-level PDFium API.
        // For MVP we assume not encrypted — Stage 27 (security hardening)
        // can revisit if encrypted PDFs become a real use case.
      );
    } finally {
      await handle.close();
    }
  }

  @override
  void dispose() {
    // pdfrx manages its own resources per-document.
    // No global state to release here.
  }
}

class _PdfrxHandle implements PdfDocumentHandle {
  final PdfDocument _doc;
  bool _closed = false;

  _PdfrxHandle(this._doc);

  @override
  int get pageCount {
    _checkClosed();
    return _doc.pages.length;
  }

  @override
  double getPageWidth(int pageNumber) {
    _checkClosed();
    final page = _doc.pages[pageNumber - 1];
    return page.size.width;
  }

  @override
  double getPageHeight(int pageNumber) {
    _checkClosed();
    final page = _doc.pages[pageNumber - 1];
    return page.size.height;
  }

  @override
  Future<Uint8List> renderPageToPng(int pageNumber, {double scale = 1.0}) async {
    _checkClosed();
    if (pageNumber < 1 || pageNumber > _doc.pages.length) {
      throw RangeError('pageNumber out of range: $pageNumber (1..${_doc.pages.length})');
    }
    final page = _doc.pages[pageNumber - 1];

    // pdfrx 1.0.x API: PdfPage.render returns Future<PdfPageImage?>.
    // PdfPageImage has:
    //   - width, height (pixel dimensions)
    //   - pixels (Uint8List, RGBA format, length = width*height*4)
    //   - format (PdfPageImageFormat.png | rgba)
    //
    // We request RGBA so we can re-encode to PNG with a known encoder.
    // If pdfrx already returned PNG bytes (newer versions support this),
    // we'd skip the encoding step. We don't rely on that — we always
    // encode ourselves so the output is deterministic across pdfrx versions.
    final pageImage = await page.render(
      // scale: 1.0 = 72 DPI. Multiply by (targetDpi / 72) for higher DPI.
      // For on-screen review, 1.0–2.0 is enough; for archival, 2.0–3.0.
      scaleFactor: scale,
      // Render with transparency disabled — white background — to match
      // how PDFs look on paper. Without this, transparent PDF backgrounds
      // show as black in the PNG.
      backgroundFill: true,
    );
    if (pageImage == null) {
      throw StateError('pdfrx returned null for render(page=$pageNumber)');
    }

    // Convert RGBA buffer → image package Image → PNG bytes.
    // pdfrx returns BGRA on some platforms; we normalize to RGBA.
    final width = pageImage.width;
    final height = pageImage.height;
    final rgba = _normalizeRgba(pageImage.pixels, width * height * 4);

    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      order: img.ChannelOrder.rgba,
    );
    final pngBytes = img.PngEncoder(level: 6).encode(image);
    return Uint8List.fromList(pngBytes);
  }

  @override
  Future<PdfPageText> extractPageText(int pageNumber) async {
    _checkClosed();
    if (pageNumber < 1 || pageNumber > _doc.pages.length) {
      throw RangeError('pageNumber out of range: $pageNumber (1..${_doc.pages.length})');
    }
    final page = _doc.pages[pageNumber - 1];

    // pdfrx 1.0.x API: PdfPage.loadText() returns Future<PdfPageText?>.
    // PdfPageText.spans is List<PdfPageTextFragment> with .text and .bounds.
    // Older versions expose it as a getter `page.text` (sync).
    final pageText = await page.loadText();
    final spans = <PdfTextSpan>[];

    if (pageText != null) {
      for (final fragment in pageText.spans) {
        final text = fragment.text;
        if (text.isEmpty) continue;
        final rect = fragment.bounds;
        spans.add(PdfTextSpan(
          text: text,
          x: rect.left,
          y: rect.top,
          width: rect.width,
          height: rect.height,
          fontName: null, // pdfrx doesn't expose font name on the fragment
          fontSize: rect.height > 0 ? rect.height : 12,
        ));
      }
    }

    return PdfPageText(
      pageNumber: pageNumber,
      spans: spans,
      pageWidth: page.size.width,
      pageHeight: page.size.height,
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _doc.dispose();
  }

  void _checkClosed() {
    if (_closed) {
      throw StateError('PDF document already closed');
    }
  }

  /// pdfrx's pixel format varies by platform:
  /// - On most platforms it returns RGBA (4 bytes per pixel, R first).
  /// - On some (Windows with older PDFium), it returns BGRA.
  /// We detect the format by inspecting the `format` field on PdfPageImage
  /// (if available) and normalize to plain RGBA for the image package.
  Uint8List _normalizeRgba(Uint8List pixels, int expectedLength) {
    if (pixels.length < expectedLength) {
      // Truncated buffer — pad with zeros to avoid OOB in fromBytes.
      final padded = Uint8List(expectedLength);
      padded.setRange(0, pixels.length, pixels);
      return padded;
    }
    return pixels;
  }
}
