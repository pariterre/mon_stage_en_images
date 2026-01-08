import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/widgets/are_you_sure_dialog.dart';
import 'package:provider/provider.dart';

class Helpers {
  static void onClickQuit(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AreYouSureDialog(
          title: 'Déconnexion',
          content: 'Êtes-vous certain(e) de vouloir vous déconnecter?',
        );
      },
    );

    if (!sure!) {
      return;
    }

    if (!context.mounted) return;
    final database = Provider.of<Database>(context, listen: false);
    RouteManager.instance.gotoLoginPage(context);
    await database.logout();
  }
}
