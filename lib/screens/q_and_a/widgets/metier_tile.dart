import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/models/all_answers.dart';
import '../../../common/models/enum.dart';
import '../../../common/models/exceptions.dart';
import '../../../common/models/section.dart';
import '../../../common/widgets/taking_action_notifier.dart';
import '../../../common/providers/all_questions.dart';
import '../../../common/providers/all_students.dart';
import '../../../common/providers/login_information.dart';

class MetierTile extends StatelessWidget {
  const MetierTile(this.sectionIndex,
      {super.key, required this.studentId, required this.onTap});

  final int sectionIndex;
  final String? studentId;
  final Function(int) onTap;

  TextStyle _pickTextStyle(BuildContext context, int? activeQuestions,
      int? answeredQuestions, int needAction) {
    if (activeQuestions == null || answeredQuestions == null) {
      return const TextStyle();
    }
    final loginType =
        Provider.of<LoginInformation>(context, listen: false).loginType;

    return TextStyle(
      color: activeQuestions > 0
          ? (answeredQuestions >= activeQuestions ? Colors.black : Colors.red)
          : Colors.grey,
      fontWeight: needAction > 0 ? FontWeight.bold : FontWeight.normal,
      fontSize: loginType == LoginType.student ? 20 : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allStudents = Provider.of<AllStudents>(context);
    final student = studentId != null ? allStudents.fromId(studentId!) : null;

    final questions = Provider.of<AllQuestions>(context, listen: false)
        .fromSection(sectionIndex);
    final loginType =
        Provider.of<LoginInformation>(context, listen: false).loginType;

    late final AllAnswers? answers;
    late final int? answered;
    late final int? active;
    if (student != null) {
      answers = student.allAnswers.fromQuestions(questions);
      answered = answers.numberAnswered;
      active = answers.numberActive;
    } else {
      answers = null;
      answered = null;
      active = null;
    }
    final int numberOfActions =
        answers != null ? answers.numberOfActionsRequired(context) : 0;

    return Card(
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: TakingActionNotifier(
          left: 6,
          top: -5,
          number: loginType == LoginType.student || numberOfActions == 0
              ? null
              : numberOfActions,
          child: ListTile(
            leading: Container(
              margin: const EdgeInsets.only(bottom: 2),
              width: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Section.color(sectionIndex)),
              child: Text(Section.letter(sectionIndex),
                  style: const TextStyle(fontSize: 25, color: Colors.white)),
            ),
            title: Text(
              Section.name(sectionIndex),
              style: _pickTextStyle(context, active, answered, numberOfActions),
            ),
            trailing: _trailingBuilder(
                context, loginType, numberOfActions, answers, answered, active),
            onTap: () => onTap(sectionIndex),
          ),
        ),
      ),
    );
  }

  Widget? _trailingBuilder(BuildContext context, LoginType loginType,
      int numberOfActions, AllAnswers? answers, int? answered, int? active) {
    if (loginType == LoginType.student) {
      return numberOfActions > 0
          ? TakingActionNotifier(
              number: numberOfActions,
              borderColor: Colors.black,
            )
          : null;
    } else if (loginType == LoginType.teacher) {
      return answers != null
          ? Text('$answered / $active',
              style: _pickTextStyle(context, active, answered, numberOfActions))
          : null;
    } else {
      throw const NotLoggedIn();
    }
  }
}