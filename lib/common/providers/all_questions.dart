import 'package:enhanced_containers/enhanced_containers.dart';
import 'package:mon_stage_en_images/common/models/answer.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/question.dart';
import 'package:mon_stage_en_images/common/models/section.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/providers/all_teacher_answers.dart';

class AllQuestions extends FirebaseListProvided<Question> with Section {
  // Constructors and (de)serializer
  static const String dataName = 'questions';

  AllQuestions({required super.onConnectionStateChanged})
      : super(pathToData: dataName);

  @override
  Question deserializeItem(data) => Question.fromSerialized(data);

  @override
  Future<void> initializeFetchingData({String? pathToData}) async {
    if (pathToData == null) {
      throw 'You must set pathToData for initializing the Questions database';
    }
    this.pathToData = pathToData;
    await super.initializeFetchingData();
  }

  ///
  /// Returns the list of questions from a section
  /// [index] is the index of the section
  Iterable<Question> fromSection(int index) {
    Iterable<Question> out = where((question) => question.section == index);
    return out;
  }

  ///
  /// Adds a question to all the students
  /// [question] is the question to add
  /// [answers] is the list of answers
  /// [currentUser] is the current user
  /// [isActive] is the map of the students and if the question is active for them
  /// [notify] is if the listeners should be notified
  void addToAll(
    Question question, {
    required AllTeacherAnswers answers,
    required User currentUser,
    Map<String, bool>? isActive,
    bool notify = true,
  }) {
    super.add(question, notify: notify);

    for (final student in answers) {
      final isActiveForStudent = isActive == null
          ? question.defaultTarget == Target.all
          : isActive[student.id]!;

      answers.addAnswers([
        Answer(
            isActive: isActiveForStudent,
            questionId: question.id,
            createdById: currentUser.id,
            studentId: student.id,
            actionRequired: ActionRequired.fromStudent)
      ]);
    }
  }

  ///
  /// Modifies a question to all the students
  /// [question] is the question to modify<>
  /// [studentAnswers] is the list of answers
  /// [currentUser] is the current user
  /// [isActive] is the map of the students and if the question is active for them
  /// [notify] is if the listeners should be notified
  void modifyToAll(
    Question question, {
    required AllTeacherAnswers studentAnswers,
    required User currentUser,
    Map<String, bool>? isActive,
    bool notify = true,
  }) {
    replace(question, notify: notify);

    for (var student in studentAnswers) {
      bool hasQuestion = false;
      for (int i = 0; i < student.answers.length; i++) {
        final answer = student.answers[i];
        if (answer.questionId != question.id) continue;

        hasQuestion = true;
        studentAnswers.modifyAnswer(answer.copyWith(
            isActive: isActive == null
                ? answer.isActive
                : isActive[answer.studentId]));
      }
      if (!hasQuestion) {
        studentAnswers.addAnswers([
          Answer(
              isActive: isActive?[student.id] ?? false,
              questionId: question.id,
              createdById: currentUser.id,
              studentId: student.id,
              actionRequired: ActionRequired.fromStudent)
        ]);
      }
    }
  }

  ///
  /// Removes a question to all the students
  /// [question] is the question to remove
  /// [answers] is the list of answers
  /// [notify] is if the listeners should be notified
  void removeToAll(
    Question question, {
    required AllTeacherAnswers answers,
    bool notify = true,
  }) {
    remove(question, notify: notify);
    answers.removeQuestion(question);
  }

  ///
  /// Returns the number of questions in the list
  int get number => length;
}
