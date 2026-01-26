import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/misc/database_helper.dart';
import 'package:mon_stage_en_images/common/models/answer.dart';
import 'package:mon_stage_en_images/common/models/answer_sort_and_filter.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/discussion.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/message.dart';
import 'package:mon_stage_en_images/common/models/question.dart';
import 'package:mon_stage_en_images/common/providers/all_answers.dart';
import 'package:provider/provider.dart';

import 'discussion_list_view.dart';

class AnswerPart extends StatefulWidget {
  const AnswerPart(
    this.question, {
    super.key,
    required this.studentId,
    required this.onStateChange,
    required this.pageMode,
    required this.filterMode,
  });

  final String? studentId;
  final VoidCallback onStateChange;
  final Question question;
  final PageMode pageMode;
  final AnswerSortAndFilter? filterMode;

  @override
  State<AnswerPart> createState() => _AnswerPartState();
}

class _AnswerPartState extends State<AnswerPart> {
  List<Message> _combineMessagesFromAllStudents(List<Answer> answers) {
    final teacherId =
        Provider.of<Database>(context, listen: false).currentUser!.id;

    // Fetch all the required answers
    var discussions = Discussion();
    for (final answer in answers) {
      for (final message in answer.discussion.toListByTime(reversed: true)) {
        final isTheRightCreatorId = widget.filterMode == null ||
            ((widget.filterMode!.fromWhomFilter
                        .contains(AnswerFromWhomFilter.studentOnly) &&
                    message.creatorId != teacherId) ||
                (widget.filterMode!.fromWhomFilter
                        .contains(AnswerFromWhomFilter.teacherOnly) &&
                    message.creatorId == teacherId));

        final isTheRightContent = widget.filterMode == null ||
            ((widget.filterMode!.contentFilter
                        .contains(AnswerContentFilter.textOnly) &&
                    !message.isPhotoUrl) ||
                (widget.filterMode!.contentFilter
                        .contains(AnswerContentFilter.photoOnly) &&
                    message.isPhotoUrl));
        final isAllowed = widget.filterMode == null ||
            DateTime.fromMicrosecondsSinceEpoch(message.creationTimeStamp)
                .isAfter(isActiveLimitDate);
        if (isTheRightCreatorId && isTheRightContent && isAllowed) {
          discussions.add(message);
        }
      }
    }

    // Filter by date if required (and default)
    return widget.filterMode == null ||
            widget.filterMode!.sorting == AnswerSorting.byDate
        ? discussions.toListByTime(reversed: true)
        : discussions.toList();
  }

  void _manageAnswerCallback({
    required String studentId,
    String? newTextEntry,
    bool? isPhoto,
    String? markAnswerAsDeleted,
    bool? markAsValidated,
  }) {
    final database = Provider.of<Database>(context, listen: false);
    final currentUser = database.currentUser!;
    final userType = database.userType;

    final allAnswers = AllAnswers.of(context, listen: false);
    final currentAnswer = allAnswers.filter(
        questionIds: [widget.question.id], studentIds: [studentId]).first;

    if (newTextEntry != null && markAnswerAsDeleted != null) {
      throw Exception(
          'You cannot add a new message and delete one at the same time.');
    } else if (newTextEntry != null) {
      currentAnswer.addToDiscussion(Message(
          studentId: studentId,
          text: newTextEntry,
          isPhotoUrl: isPhoto ?? false,
          creatorId: currentUser.id,
          isDeleted: false));
    } else if (markAnswerAsDeleted != null) {
      final index = currentAnswer.discussion
          .indexWhere((message) => message.id == markAnswerAsDeleted);
      currentAnswer.discussion[index] =
          currentAnswer.discussion[index].copyWith(isDeleted: true);
    }

    // Inform the changing of status
    final newStatus = switch (userType) {
      UserType.none => ActionRequired.none,
      UserType.student => ActionRequired.fromTeacher,
      UserType.teacher => (markAsValidated ?? false)
          // If the teacher marked as valided but left a comment, the student should be notified
          ? (newTextEntry == null
              ? ActionRequired.none
              : ActionRequired.fromStudent)
          : ActionRequired.fromStudent,
    };

    allAnswers.modifyAnswer(currentAnswer.copyWith(
      actionRequired: newStatus,
      isValidated: markAsValidated,
    ));

    widget.onStateChange();
  }

  @override
  Widget build(BuildContext context) {
    final answers = AllAnswers.of(context, listen: false).filter(
        questionIds: [widget.question.id],
        studentIds:
            widget.studentId == null ? null : [widget.studentId!]).toList();

    final messages = _combineMessagesFromAllStudents(answers);
    final isValidated = answers.length == 1 ? answers[0].isValidated : false;

    return Container(
      padding: const EdgeInsets.only(left: 40, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.pageMode != PageMode.edit)
            DiscussionListView(
              studentId: widget.studentId,
              messages: messages,
              isAnswerValidated: isValidated,
              question: widget.question,
              manageAnswerCallback: _manageAnswerCallback,
            ),
          const SizedBox(height: 15)
        ],
      ),
    );
  }
}
