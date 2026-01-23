import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/misc/date_formatting.dart';
import 'package:mon_stage_en_images/common/misc/storage_service.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/message.dart';
import 'package:mon_stage_en_images/common/models/themes.dart';
import 'package:mon_stage_en_images/common/widgets/are_you_sure_dialog.dart';
import 'package:provider/provider.dart';

class DiscussionTile extends StatelessWidget {
  const DiscussionTile({
    super.key,
    required this.discussion,
    required this.isLast,
    required this.onDeleted,
  });

  final Message discussion;
  final bool isLast;
  final Function()? onDeleted;

  void _showImageFullScreen(BuildContext context,
      {required Uint8List imageData}) {
    showDialog(
        context: context,
        builder: (context) => GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AlertDialog(
                  content: Image.memory(imageData, fit: BoxFit.contain)),
            ));
  }

  Future<void> _deleteMessage(BuildContext context) async {
    onDeleted!();
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<Database>(context, listen: false);
    final currentUser = database.currentUser!;
    final userType = database.userType;

    final Color myColor = userType == UserType.student
        ? studentTheme().colorScheme.primary
        : teacherTheme().colorScheme.primary;
    final Color otherColor = userType == UserType.student
        ? teacherTheme().colorScheme.primary
        : studentTheme().colorScheme.primary;

    return Padding(
      padding: discussion.creatorId == currentUser.id
          ? const EdgeInsets.only(left: 30.0)
          : const EdgeInsets.only(right: 30.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: discussion.creatorId == currentUser.id
              ? myColor.withAlpha(80)
              : otherColor.withAlpha(80),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (discussion.isPhotoUrl)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _showNameOfSender(),
                  if (onDeleted != null && !discussion.isDeleted)
                    _DeleteButton(
                        messageAuthorId: discussion.creatorId,
                        onTap: () => _deleteMessage(context)),
                ],
              ),
            if (discussion.isPhotoUrl)
              FutureBuilder<Uint8List?>(
                  future: StorageService.getImage(discussion.text),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 1 / 4,
                          ),
                          const CircularProgressIndicator(),
                        ],
                      );
                    }

                    return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(left: 15, bottom: 5),
                        child: InkWell(
                          onTap: () => _showImageFullScreen(context,
                              imageData: snapshot.data!),
                          child: SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 1 / 4,
                              child: Image.memory(snapshot.data!,
                                  fit: BoxFit.cover)),
                        ));
                  }),
            if (!discussion.isPhotoUrl)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _showNameOfSender(),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      discussion.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  )),
                  if (onDeleted != null && !discussion.isDeleted)
                    _DeleteButton(
                        messageAuthorId: discussion.creatorId,
                        onTap: () => _deleteMessage(context)),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(discussion.creationTimeStamp.toFullDateFromEpoch()),
                const SizedBox(width: 8),
                if (discussion.creatorId == currentUser.id && isLast) ...[
                  Icon(
                    Icons.check,
                    color: Colors.blueGrey.withAlpha(150),
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'envoyé',
                    style: TextStyle(color: Colors.blueGrey.withAlpha(150)),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _showNameOfSender() {
    return Text('${discussion.name} : ',
        style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: 18));
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.messageAuthorId, required this.onTap});

  final String messageAuthorId;
  final Function() onTap;

  Future<void> _showConfirmationDialog(BuildContext context) async {
    final bool? confirmDelete = await showDialog(
        context: context,
        builder: (context) => AreYouSureDialog(
              title: 'Supprimer le message',
              canReadAloud: true,
              content: 'Êtes-vous sûr de vouloir supprimer ce message ?',
              onConfirmed: () => Navigator.of(context).pop(true),
              onCancelled: () => Navigator.of(context).pop(false),
            ));

    if (confirmDelete == true) {
      onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<Database>(context, listen: false);
    final currentUser = database.currentUser!;
    final userType = database.userType;

    if (messageAuthorId != currentUser.id && userType != UserType.teacher) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.red.withAlpha(50),
          onTap: () => _showConfirmationDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child:
                Icon(Icons.delete, color: Colors.red.withAlpha(200), size: 20),
          )),
    );
  }
}
