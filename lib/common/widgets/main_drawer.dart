import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/helpers.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/screens/login/go_to_irsst_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    this.showTitle = true,
    this.iconOnly = false,
    this.canPop = true,
    this.roundedCorners = true,
  });

  static MainDrawer get small => const MainDrawer();
  static MainDrawer get medium =>
      const MainDrawer(iconOnly: true, canPop: false, roundedCorners: false);
  static MainDrawer get large =>
      const MainDrawer(canPop: false, roundedCorners: false);

  final bool showTitle;
  final bool iconOnly;
  final bool canPop;
  final bool roundedCorners;

  @override
  Widget build(BuildContext context) {
    final userType =
        Provider.of<Database>(context, listen: false).currentUser?.userType ??
            UserType.student;

    return Drawer(
      width: iconOnly ? 120.0 : null,
      shape: roundedCorners
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0.0),
            ),
      child: Scaffold(
        appBar: showTitle
            ? AppBar(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.menu),
                    SizedBox(width: 8.0),
                    if (!iconOnly) const Text('Menu principal'),
                  ],
                ),
                automaticallyImplyLeading: false,
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userType == UserType.teacher)
              MenuItem(
                title: 'Mes élèves',
                icon: Icons.person,
                onTap: () => RouteManager.instance.gotoStudentsPage(context),
                iconOnly: iconOnly,
              ),
            if (userType == UserType.teacher)
              MenuItem(
                title: 'Gestion des questions',
                icon: Icons.speaker_notes,
                onTap: () => RouteManager.instance.gotoQAndAPage(context,
                    target: Target.all, pageMode: PageMode.edit, student: null),
                iconOnly: iconOnly,
              ),
            if (userType == UserType.teacher) const Divider(),
            if (userType == UserType.teacher)
              MenuItem(
                title: 'Résumé des réponses',
                icon: Icons.question_answer,
                onTap: () => RouteManager.instance.gotoQAndAPage(context,
                    target: Target.all,
                    pageMode: PageMode.fixView,
                    student: null),
                iconOnly: iconOnly,
              ),
            if (userType == UserType.teacher) const Divider(),
            if (userType == UserType.teacher)
              MenuItem(
                title: 'Apprendre sur la SST',
                icon: Icons.web,
                onTap: () async {
                  await launchUrl(GoToIrsstScreen.url);
                  if (!context.mounted) return;
                  if (canPop) Navigator.of(context).pop();
                },
                iconOnly: iconOnly,
              ),
            if (userType == UserType.teacher) const Divider(),
            if (userType == UserType.teacher)
              Column(children: [
                MenuItem(
                  title: 'Revoir le tutoriel',
                  icon: Icons.help,
                  onTap: () => SharedPreferencesController
                      .instance.hasSeenOnboarding = true,
                  iconOnly: iconOnly,
                ),
                const Divider(),
              ]),
            MenuItem(
              title: 'Déconnexion',
              icon: Icons.exit_to_app,
              onTap: () => Helpers.onClickQuit(context),
              iconOnly: iconOnly,
            )
          ],
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.iconColor,
    required this.iconOnly,
  });

  final String title;
  final VoidCallback? onTap;
  final Color? iconColor;
  final IconData icon;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.secondary,
        ),
        title: iconOnly
            ? null
            : Text(title, style: Theme.of(context).textTheme.titleLarge),
        onTap: onTap,
      ),
    );
  }
}
