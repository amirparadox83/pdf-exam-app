/// Rule-Based Question Parser — Stage 14
/// Deterministic, no AI, no LLM, no cloud.
/// Detects question numbers, bodies, options, labels, boundaries.

import '../../domain/entities/entities.dart';
import '../pdf_extraction/pdf_extractor.dart';

abstract class QuestionParser {
  /// Parse extracted blocks from a PDF page into questions.
  List<DetectedQuestion> parseBlocks(List<PdfBlock> blocks, {int startPageNumber = 1});

  /// Parse a single block into a question (if it looks like one).
  DetectedQuestion? parseBlock(PdfBlock block, {int pageNumber = 1});
}

class RuleBasedQuestionParser implements QuestionParser {
  /// Configurable parsing rules.
  final ParserConfig config;

  RuleBasedQuestionParser({ParserConfig? config}) : config = config ?? const ParserConfig();

  @override
  List<DetectedQuestion> parseBlocks(List<PdfBlock> blocks, {int startPageNumber = 1}) {
    final questions = <DetectedQuestion>[];
    DetectedQuestion? current;
    final optionBuffer = <DetectedOption>[];

    void flush() {
      if (current != null) {
        current = current!.copyWith(options: List.from(optionBuffer));
        questions.add(current!);
        current = null;
        optionBuffer.clear();
      }
    }

    for (final block in blocks) {
      final lines = block.text.split('\n');
      for (final line in lines) {
        final qn = _detectQuestionNumber(line);
        final opt = _detectOption(line);

        if (qn != null) {
          flush();
          current = DetectedQuestion(
            number: qn,
            body: _stripQuestionNumber(line, qn),
            options: [],
            pageNumber: startPageNumber,
            region: PdfRegion(
              pageNumber: startPageNumber,
              x: block.x,
              y: block.y,
              width: block.width,
              height: block.height,
            ),
            warnings: [],
            status: QuestionStatus.valid,
          );
        } else if (opt != null && current != null) {
          optionBuffer.add(opt);
        } else if (current != null) {
          // Continuation of question body or option
          if (optionBuffer.isEmpty) {
            current = current!.copyWith(body: '${current!.body}\n$line');
          } else {
            final last = optionBuffer.last;
            optionBuffer.removeLast();
            optionBuffer.add(last.copyWith(text: '${last.text}\n$line'));
          }
        }
      }
    }
    flush();

    // Post-process: validate each question.
    return questions.map(_validate).toList();
  }

  @override
  DetectedQuestion? parseBlock(PdfBlock block, {int pageNumber = 1}) {
    final result = parseBlocks([block], startPageNumber: pageNumber);
    return result.isEmpty ? null : result.first;
  }

  /// Detect Persian or Latin question number at the start of a line.
  /// Supports:
  ///   1.  /  ۱.
  ///   1)  /  ۱)
  ///   1-  /  ۱-
  ///   Q1 /  سؤال ۱
  int? _detectQuestionNumber(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    // Persian/Latin digit patterns with optional separator
    final patterns = [
      RegExp(r'^(\d{1,3})[.)\-]\s'),
      RegExp(r'^([\u06F0-\u06F9]{1,3})[.)\-]\s'),
      RegExp(r'^([\u0660-\u0669]{1,3})[.)\-]\s'),
      RegExp(r'^(?:Q|q|سؤال|سوال|Question)\s*[:\-]?\s*(\d{1,3})\s*[.)\-]?'),
      RegExp(r'^(?:Q|q|سؤال|سوال|Question)\s*[:\-]?\s*([\u06F0-\u06F9]{1,3})\s*[.)\-]?'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(trimmed);
      if (m != null) {
        return _normalizeDigits(m.group(1)!);
      }
    }
    return null;
  }

  /// Detect a single option line:
  ///   الف)  /  ب)  /  ج)  /  د)
  ///   A) / B) / C) / D)
  ///   1)  /  2)  /  ۳)
  DetectedOption? _detectOption(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    // Persian letters الف ب ج د
    final persianLetters = RegExp(r'^([الفبجدهزحطییکمنپتجچحخدذرزژسشصضطظعغفقکگلمنوهی])\s*[)\.\-:]');
    final m1 = persianLetters.firstMatch(trimmed);
    if (m1 != null) {
      return DetectedOption(
        label: m1.group(1)!,
        text: trimmed.substring(m1.end).trim(),
        order: 0,
      );
    }

    // Latin A) B) C) D) (single char)
    final latinLetters = RegExp(r'^([A-Da-d])\s*[)\.\-:]');
    final m2 = latinLetters.firstMatch(trimmed);
    if (m2 != null) {
      return DetectedOption(
        label: m2.group(1)!.toUpperCase(),
        text: trimmed.substring(m2.end).trim(),
        order: 0,
      );
    }

    // Numbered 1) 2) 3) 4) — but not if it looks like a question number
    // (question numbers are usually at start of line, options too, so we
    // disambiguate by context: if there is already a current question, a
    // number followed by ) is more likely an option).
    final numbered = RegExp(r'^(\d{1,2}|[\u06F0-\u06F9]{1,2})\s*[)\-]');
    final m3 = numbered.firstMatch(trimmed);
    if (m3 != null) {
      // Skip if the rest of the line is very long (likely a question, not an option)
      final rest = trimmed.substring(m3.end).trim();
      if (rest.length > 0 && rest.length < 200) {
        return DetectedOption(
          label: m3.group(1)!,
          text: rest,
          order: 0,
        );
      }
    }

    return null;
  }

  String _stripQuestionNumber(String line, int number) {
    final trimmed = line.trim();
    // Strip leading number and separator
    final stripPatterns = [
      RegExp(r'^\d{1,3}[.)\-]\s*'),
      RegExp(r'^[\u06F0-\u06F9]{1,3}[.)\-]\s*'),
      RegExp(r'^[\u0660-\u0669]{1,3}[.)\-]\s*'),
      RegExp(r'^(?:Q|q|سؤال|سوال|Question)\s*[:\-]?\s*\d{1,3}\s*[.)\-]?\s*'),
      RegExp(r'^(?:Q|q|سؤال|سوال|Question)\s*[:\-]?\s*[\u06F0-\u06F9]{1,3}\s*[.)\-]?\s*'),
    ];
    for (final p in stripPatterns) {
      final result = p.replaceFirst(trimmed, '');
      if (result != trimmed) return result.trim();
    }
    return trimmed;
  }

  int _normalizeDigits(String s) {
    final persian = s.replaceAll(RegExp(r'[\u06F0-\u06F9]'), (m) => String.fromCharCode(m.codeUnitAt(0) - 0x06F0 + 0x30));
    final arabic = persian.replaceAll(RegExp(r'[\u0660-\u0669]'), (m) => String.fromCharCode(m.codeUnitAt(0) - 0x0660 + 0x30));
    return int.parse(arabic);
  }

  DetectedQuestion _validate(DetectedQuestion q) {
    final warnings = <String>[];
    QuestionStatus status = QuestionStatus.valid;

    if (q.body.trim().isEmpty) {
      warnings.add('بدنه سؤال خالی است');
      status = QuestionStatus.invalid;
    }
    if (q.options.isEmpty) {
      warnings.add('هیچ گزینه‌ای شناسایی نشد');
      status = QuestionStatus.suspicious;
    } else if (q.options.length < 2) {
      warnings.add('فقط ${q.options.length} گزینه شناسایی شد (کمتر از ۴)');
      status = QuestionStatus.suspicious;
    } else if (q.options.length != 4 && !config.allowNonFourOptions) {
      warnings.add('تعداد گزینه‌ها ${q.options.length} است (پیش‌فرض: ۴)');
      status = QuestionStatus.suspicious;
    }
    // Check for empty option texts
    if (q.options.any((o) => o.text.trim().isEmpty)) {
      warnings.add('برخی گزینه‌ها متن خالی دارند');
      status = QuestionStatus.suspicious;
    }
    // Check for duplicate option labels
    final labels = q.options.map((o) => o.label).toSet();
    if (labels.length != q.options.length) {
      warnings.add('برچسب گزینه‌ها تکراری است');
      status = QuestionStatus.suspicious;
    }

    return q.copyWith(warnings: warnings, status: status);
  }
}

class ParserConfig {
  final bool allowNonFourOptions;
  final bool supportPersianLetters;
  final bool supportLatinLetters;
  final bool supportNumberedOptions;

  const ParserConfig({
    this.allowNonFourOptions = false,
    this.supportPersianLetters = true,
    this.supportLatinLetters = true,
    this.supportNumberedOptions = true,
  });
}

class DetectedQuestion {
  final int number;
  final String body;
  final List<DetectedOption> options;
  final int pageNumber;
  final PdfRegion? region;
  final List<String> warnings;
  final QuestionStatus status;

  DetectedQuestion({
    required this.number,
    required this.body,
    required this.options,
    required this.pageNumber,
    this.region,
    required this.warnings,
    required this.status,
  });

  DetectedQuestion copyWith({
    int? number,
    String? body,
    List<DetectedOption>? options,
    int? pageNumber,
    PdfRegion? region,
    List<String>? warnings,
    QuestionStatus? status,
  }) {
    return DetectedQuestion(
      number: number ?? this.number,
      body: body ?? this.body,
      options: options ?? this.options,
      pageNumber: pageNumber ?? this.pageNumber,
      region: region ?? this.region,
      warnings: warnings ?? this.warnings,
      status: status ?? this.status,
    );
  }
}

class DetectedOption {
  final String label;
  final String text;
  final int order;
  final PdfRegion? region;

  DetectedOption({
    required this.label,
    required this.text,
    required this.order,
    this.region,
  });

  DetectedOption copyWith({
    String? label,
    String? text,
    int? order,
    PdfRegion? region,
  }) {
    return DetectedOption(
      label: label ?? this.label,
      text: text ?? this.text,
      order: order ?? this.order,
      region: region ?? this.region,
    );
  }
}
