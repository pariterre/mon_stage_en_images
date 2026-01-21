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
        return AreYouSureDialog(
          title: 'Déconnexion',
          content: 'Êtes-vous certain(e) de vouloir vous déconnecter?',
          onCancelled: () => Navigator.pop(context, false),
          onConfirmed: () => Navigator.pop(context, true),
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

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Ajouter un mot de passe';
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  static String? passwordConfirmationValidator(
      String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Confirmer le mot de passe';
    }
    if (password != confirmation) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  static String? emailValidator(String? email) {
    if (email == null) return 'Ajouter une adresse courriel';

    final emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
    final regex = RegExp(emailPattern);
    return regex.hasMatch(email) ? null : 'Adresse courriel invalide';
  }
}
