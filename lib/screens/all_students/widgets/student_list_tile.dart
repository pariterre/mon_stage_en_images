import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/providers/all_answers.dart';
import 'package:mon_stage_en_images/common/widgets/avatar_tab.dart';
import 'package:mon_stage_en_images/common/widgets/taking_action_notifier.dart';
import 'package:provider/provider.dart';

class StudentListTile extends StatelessWidget {
  const StudentListTile(
    this.studentId, {
    super.key,
    required this.modifyStudentCallback,
  });

  final Function(User) modifyStudentCallback;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<Database>(context, listen: false);
    final currentUser = database.currentUser;

    final student =
        database.students.firstWhereOrNull((e) => e.id == studentId);

    final allAnswers =
        AllAnswers.of(context, listen: false).filter(studentIds: [studentId]);
    final numberOfActions =
        AllAnswers.numberNeedTeacherActionFrom(allAnswers, context);

    return Card(
      elevation: 5,
      child: ListTile(
        title: Row(
          children: [
            if (student != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AvatarTab(user: student),
              ),
            Text(student?.toString() ?? '',
                style: const TextStyle(fontSize: 20)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                student?.id != null
                    ? currentUser?.studentNotes[student!.id] ?? ''
                    : '',
                style: const TextStyle(fontSize: 16)),
            Text(
                'Questions répondues : ${AllAnswers.numberAnsweredFrom(allAnswers)} '
                '/ ${AllAnswers.numberActiveFrom(allAnswers)}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TakingActionNotifier(
              number: numberOfActions == 0 ? null : numberOfActions,
              padding: 10,
              borderColor: Colors.black,
              child: const Text(""),
            ),
            IconButton(
                onPressed: () {
                  if (student == null) return;
                  modifyStudentCallback(student);
                },
                icon: Icon(Icons.more_horiz))
          ],
        ),
        onTap: () => RouteManager.instance.gotoQAndAPage(context,
            target: Target.individual,
            pageMode: PageMode.editableView,
            student: student),
        onLongPress: () {
          if (student == null) return;
          modifyStudentCallback(student);
        },
      ),
    );
  }
}
