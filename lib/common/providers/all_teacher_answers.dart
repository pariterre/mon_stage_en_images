import 'package:enhanced_containers/enhanced_containers.dart';
import 'package:mon_stage_en_images/common/models/answer.dart';
import 'package:mon_stage_en_images/common/models/question.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/providers/all_answers.dart';

class AllTeacherAnswers extends FirebaseListProvided<StudentAnswers>
    implements AllAnswers {
  int get count => length;
  static const String dataName = 'answers';
  List<User>? connectedStudents;

  AllTeacherAnswers() : super(pathToData: dataName);

  @override
  Future<void> initializeFetchingData(
      {String? pathToData, List<User>? connectedStudents}) async {
    if (pathToData == null) {
      throw 'You must set pathToData for initializing the answers database for teachers';
    }
    if (connectedStudents == null) {
      throw 'You must set connectedStudents for initializing the answers database for teachers';
    }
    this.pathToData = pathToData;
    this.connectedStudents = connectedStudents;
    await super.initializeFetchingData();
  }

  @override
  Future<void> stopFetchingData() async {
    await super.stopFetchingData();
    connectedStudents = null;
    pathToData = '';
  }

  /// Remove answers from non-registered students (it happens when a student
  /// removed themselves from the group)
  @override
  void onItemAdded(String id) {
    // If the student exists in the database, do nothing
    if (connectedStudents!.any((s) => s.id == id)) return;

    rawList.removeWhere((a) => a.id == id);
  }

  @override
  StudentAnswers deserializeItem(data) {
    return StudentAnswers.fromSerialized(data);
  }

  ///
  /// Returns if the question is active for all the students who has it
  bool isQuestionActiveForAll(Question question) => every((a) {
        final index = a.answers.indexWhere((q) => q.questionId == question.id);
        // If the question does not exist for that student, it is technically not inactive
        if (index == -1) return true;
        return a.answers[index].isActive;
      });

  ///
  /// Returns if the question is inactive for all the students who has it
  bool isQuestionInactiveForAll(Question question) => every((a) {
        final index = a.answers.indexWhere((q) => q.questionId == question.id);
        // If the question does not exist for that student, it is technically not inactive
        if (index == -1) return true;
        return !a.answers[index].isActive;
      });

  @override
  void add(StudentAnswers item, {bool notify = true}) =>
      throw 'Use the "addAnswers" or "removeQuestion" methods instead';

  @override
  Future<void> replace(StudentAnswers item, {bool notify = true}) =>
      throw 'Use the "addAnswers" of "removeQuestion" methods instead';

  Future<StudentAnswers> _getOrSetStudentAnswers(String studentId,
      {int maxRetry = 10}) async {
    final studentAnswers = firstWhereOrNull((e) => e.id == studentId);
    if (studentAnswers != null) return studentAnswers;

    super.add(StudentAnswers([], studentId: studentId));

    while (true) {
      // Wait for the database to be updated
      await Future.delayed(const Duration(milliseconds: 100));

      final studentAnswers = firstWhereOrNull((e) => e.id == studentId);
      if (studentAnswers != null) return studentAnswers;

      maxRetry--;
      if (maxRetry == 0) throw 'Could not add the new student';
    }
  }

  @override
  Future<void> addAnswers(Iterable<Answer> answers,
      {bool notify = true}) async {
    final Map<String, StudentAnswers> studentAnswers = {};
    for (final answer in answers) {
      if (!studentAnswers.keys.contains(answer.studentId)) {
        // Get (or create) all the required StudentAnswers
        studentAnswers[answer.studentId] =
            await _getOrSetStudentAnswers(answer.studentId);
      }

      final index = studentAnswers[answer.studentId]!
          .answers
          .indexWhere((e) => e.questionId == answer.questionId);
      if (index != -1) {
        studentAnswers[answer.studentId]!.answers[index] = answer;
      } else {
        studentAnswers[answer.studentId]!.answers.add(answer);
      }
    }

    for (final studentAnswer in studentAnswers.values) {
      await super.replace(studentAnswer, notify: notify);
    }

    if (notify) notifyListeners();
  }

  @override
  void modifyAnswer(Answer answer, {bool notify = true}) =>
      addAnswers([answer], notify: notify);

  @override
  Iterable<Answer> filter({
    Iterable<String>? questionIds,
    Iterable<String>? studentIds,
    bool? isActive,
    bool? isAnswered,
    bool? hasAnswer,
  }) =>
      expand((e) => e.answers.where((q) =>
          (questionIds == null || questionIds.contains(q.questionId)) &&
          (studentIds == null || studentIds.contains(q.studentId)) &&
          (isActive == null || q.isActive == isActive) &&
          (isAnswered == null || q.isAnswered == isAnswered) &&
          (hasAnswer == null || q.hasAnswer == hasAnswer)));

  Future<void> removeQuestion(Question question) async {
    for (final student in this) {
      final toRemove =
          student.answers.indexWhere((e) => e.questionId == question.id);
      if (toRemove != -1) student.answers.removeAt(toRemove);

      await super.replace(student);
    }
    notifyListeners();
  }
}
