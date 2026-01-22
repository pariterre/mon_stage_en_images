import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/models/answer.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/providers/all_student_answers.dart';
import 'package:mon_stage_en_images/common/providers/all_teacher_answers.dart';
import 'package:provider/provider.dart';

abstract class AllAnswers {
  static AllAnswers of(BuildContext context, {bool listen = true}) {
    switch (Provider.of<Database>(context, listen: listen).userType) {
      case UserType.none:
        throw 'No AllAnswers for UserType.none';
      case UserType.student:
        return Provider.of<AllStudentAnswers>(context, listen: listen);
      case UserType.teacher:
        return Provider.of<AllTeacherAnswers>(context, listen: listen);
    }
  }

  ///
  /// Adds answers to the database
  Future<void> addAnswers(Iterable<Answer> answers, {bool notify = true});

  ///
  /// Modifies an answer in the database
  void modifyAnswer(Answer answer, {bool notify = true});

  ///
  /// Returns the answers filtered by the [questionIds], [studentIds], [isActive] and [isAnswered]
  /// [questionIds] is the list of questions
  /// [studentIds] is the list of student ids
  /// [isActive] is if the answer is active
  /// [isAnswered] is if the answer is answered
  Iterable<Answer> filter({
    Iterable<String>? questionIds,
    Iterable<String>? studentIds,
    bool? isActive,
    bool? isAnswered,
    bool? hasAnswer,
  });

  ///
  /// Returns the number of active answers in the list
  /// [answers] is the list of answers to check
  static int numberActiveFrom(Iterable<Answer> answers) =>
      answers.fold(0, (int prev, e) => prev + (e.isActive ? 1 : 0));

  ///
  /// Returns the number of answered answers in the list
  /// [answers] is the list of answers to check
  static int numberAnsweredFrom(Iterable<Answer> answers) =>
      answers.fold(0, (int prev, e) => prev + (e.isAnswered ? 1 : 0));

  ///
  /// Returns the number of actions required from the user
  /// [context] is required to get the current user
  /// [answers] is the list of answers to check
  static int numberOfActionsRequiredFrom(
      Iterable<Answer> answers, BuildContext context) {
    switch (Provider.of<Database>(context, listen: false).userType) {
      case UserType.none:
        return 0;
      case UserType.student:
      case UserType.teacher:
        return numberNeedStudentActionFrom(answers, context);
    }
  }

  ///
  /// Returns the number of actions required from the teacher
  /// [answers] is the list of answers to check
  /// [ctx] is required to get the current user
  static int numberNeedTeacherActionFrom(
          Iterable<Answer> answers, BuildContext ctx) =>
      answers.fold(
          0,
          (int prev, e) =>
              prev + (e.action(ctx) == ActionRequired.fromTeacher ? 1 : 0));

  ///
  /// Returns the number of actions required from the student
  /// [answers] is the list of answers to check
  /// [context] is required to get the current user
  static int numberNeedStudentActionFrom(
          Iterable<Answer> answers, BuildContext context) =>
      answers.fold(
          0,
          (int prev, e) =>
              prev + (e.action(context) == ActionRequired.fromStudent ? 1 : 0));
}
