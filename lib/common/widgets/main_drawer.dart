import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/helpers.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/default_onboarding_steps.dart';
import 'package:mon_stage_en_images/onboarding/onboarding.dart';
import 'package:mon_stage_en_images/screens/login/go_to_irsst_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    this.iconOnly = false,
    this.canPop = true,
    this.roundedCorners = true,
    this.canNavigateBack,
    this.navigationBack,
  });

  static MainDrawer small({Function()? navigationBack}) => MainDrawer(
      iconOnly: false,
      canPop: true,
      roundedCorners: true,
      navigationBack: navigationBack);
  static MainDrawer medium({Function()? navigationBack}) => MainDrawer(
      iconOnly: true,
      canPop: false,
      roundedCorners: false,
      navigationBack: navigationBack);
  static MainDrawer large({Function()? navigationBack}) => MainDrawer(
      iconOnly: false,
      canPop: false,
      roundedCorners: false,
      navigationBack: navigationBack);

  final bool iconOnly;
  final bool canPop;
  final bool roundedCorners;
  final bool? canNavigateBack;
  final Function()? navigationBack;

  @override
  Widget build(BuildContext context) {
    final userType = Provider.of<Database>(context, listen: false).userType;

    return Drawer(
      width: iconOnly ? 120.0 : null,
      shape: roundedCorners
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0.0),
            ),
      child: Scaffold(
        appBar: AppBar(
          leading: navigationBack == null
              ? null
              : IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: navigationBack,
                ),
          title: OnboardingContainer(
            onInitialize: (context) =>
                onboardingContexts['drawer_button'] = context,
            child: navigationBack == null
                ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Icon(Icons.menu),
                    SizedBox(width: 8.0),
                    if (!iconOnly) Text('Menu principal'),
                  ])
                : SizedBox.shrink(),
          ),
        ),
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
              OnboardingContainer(
                onInitialize: (context) =>
                    onboardingContexts['drawer_question_button'] = context,
                child: MenuItem(
                  title: 'Gestion des questions',
                  icon: Icons.speaker_notes,
                  onTap: () => RouteManager.instance.gotoQAndAPage(context,
                      target: Target.all,
                      pageMode: PageMode.edit,
                      student: null),
                  iconOnly: iconOnly,
                ),
              ),
            if (userType == UserType.teacher) const Divider(),
            if (userType == UserType.teacher)
              OnboardingContainer(
                onInitialize: (context) =>
                    onboardingContexts['drawer_answer_button'] = context,
                child: MenuItem(
                  title: 'Résumé des réponses',
                  icon: Icons.question_answer,
                  onTap: () => RouteManager.instance.gotoQAndAPage(context,
                      target: Target.all,
                      pageMode: PageMode.fixView,
                      student: null),
                  iconOnly: iconOnly,
                ),
              ),
            if (userType == UserType.teacher) const Divider(),
            if (userType == UserType.teacher)
              OnboardingContainer(
                onInitialize: (context) =>
                    onboardingContexts['drawer_info_button'] = context,
                child: MenuItem(
                  title: 'Apprendre sur la SST',
                  icon: Icons.web,
                  onTap: () async {
                    await launchUrl(GoToIrsstScreen.url);
                    if (!context.mounted) return;
                    if (canPop) Navigator.of(context).pop();
                  },
                  iconOnly: iconOnly,
                ),
              ),
            if (userType == UserType.teacher) const Divider(),
            if (userType == UserType.teacher)
              Column(children: [
                MenuItem(
                  title: 'Revoir le tutoriel',
                  icon: Icons.help,
                  onTap: () => SharedPreferencesController
                      .instance.hasSeenOnboarding = false,
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
