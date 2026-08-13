/// Repository contracts (abstract) — domain layer
/// Stage 05 — Architecture
/// These are the interfaces that the data layer must implement.
/// The presentation layer depends on these, not on concrete implementations.

import '../entities/entities.dart';

abstract class QuestionRepository {
  Future<Question?> getById(String id);
  Future<List<Question>> getAll({int limit = 100, int offset = 0});
  Future<List<Question>> search(String query);
  Future<List<Question>> filter({
    String? subjectId,
    String? topicId,
    String? sourceId,
    List<String>? tagIds,
    Difficulty? difficulty,
    bool? onlyBookmarked,
    bool? onlyMistakes,
    bool? onlyNeedsReview,
    bool? excludeArchived,
    int limit = 100,
    int offset = 0,
  });
  Future<int> count();
  Future<String> insert(Question question);
  Future<void> update(Question question);
  Future<void> delete(String id);
  Future<void> archive(String id);
  Future<void> toggleBookmark(String id);
  Future<void> markAnswered(String id, bool correct);
}

abstract class SubjectRepository {
  Future<Subject?> getById(String id);
  Future<List<Subject>> getAll();
  Future<String> insert(Subject subject);
  Future<void> update(Subject subject);
  Future<void> delete(String id);
}

abstract class TopicRepository {
  Future<Topic?> getById(String id);
  Future<List<Topic>> getBySubject(String subjectId);
  Future<String> insert(Topic topic);
  Future<void> update(Topic topic);
  Future<void> delete(String id);
}

abstract class TagRepository {
  Future<List<Tag>> getAll();
  Future<String> insert(Tag tag);
  Future<void> delete(String id);
}

abstract class PdfRepository {
  Future<PdfSource?> getById(String id);
  Future<List<PdfSource>> getAll();
  Future<String> insert(PdfSource pdf);
  Future<void> update(PdfSource pdf);
  Future<void> delete(String id);
  Future<List<PdfPage>> getPages(String pdfId);
  Future<void> insertPage(PdfPage page);
}

abstract class ExamRepository {
  Future<Exam?> getById(String id);
  Future<List<Exam>> getAll({int limit = 50, int offset = 0});
  Future<String> insert(Exam exam);
  Future<void> update(Exam exam);
  Future<void> delete(String id);
  Future<void> saveAnswer(ExamAnswer answer);
  Future<ExamAnswer?> getAnswer(String examId, String questionId);
  Future<List<ExamAnswer>> getAnswers(String examId);
  Future<void> clearAnswers(String examId);
}

abstract class ResultRepository {
  Future<ExamResult?> getById(String id);
  Future<List<ExamResult>> getAll({int limit = 50, int offset = 0});
  Future<String> insert(ExamResult result);
  Future<void> delete(String id);
}

abstract class MistakeRepository {
  Future<Mistake?> getByQuestion(String questionId);
  Future<List<Mistake>> getAll({int limit = 200, int offset = 0});
  Future<String> insert(Mistake mistake);
  Future<void> update(Mistake mistake);
  Future<void> delete(String id);
  Future<void> markCorrectStreak(String questionId, bool correct);
}

abstract class ReviewRepository {
  Future<ReviewSchedule?> getByQuestion(String questionId);
  Future<List<ReviewSchedule>> getDue({DateTime? asOf, int limit = 50});
  Future<String> insert(ReviewSchedule schedule);
  Future<void> update(ReviewSchedule schedule);
  Future<void> delete(String id);
}

abstract class NoteRepository {
  Future<List<Note>> getByQuestion(String questionId);
  Future<String> insert(Note note);
  Future<void> update(Note note);
  Future<void> delete(String id);
}

abstract class BackupRepository {
  Future<List<BackupMetadata>> getAll();
  Future<String> insert(BackupMetadata metadata);
  Future<void> delete(String id);
}
