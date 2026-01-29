import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/helpers.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/providers/database.dart';
import 'package:mon_stage_en_images/default_onboarding_steps.dart';
import 'package:mon_stage_en_images/onboarding/onboarding.dart';
import 'package:mon_stage_en_images/screens/suggestions/suggestions_page.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    this.iconOnly = false,
    this.roundedCorners = true,
    this.navigationBack,
  });

  static MainDrawer small({Function()? navigationBack}) => MainDrawer(
      iconOnly: false, roundedCorners: true, navigationBack: navigationBack);
  static MainDrawer medium({Function()? navigationBack}) => MainDrawer(
      iconOnly: true, roundedCorners: false, navigationBack: navigationBack);
  static MainDrawer large({Function()? navigationBack}) => MainDrawer(
      iconOnly: false, roundedCorners: false, navigationBack: navigationBack);

  final bool iconOnly;
  final bool roundedCorners;
  final Function()? navigationBack;

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<Database>(context, listen: false);
    final user = database.currentUser;
    if (user == null) {
      return SizedBox.shrink();
    }
    final userType = database.userType;

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
              ? (Navigator.of(context).canPop()
                  ? BackButton(color: Theme.of(context).colorScheme.onPrimary)
                  : Icon(Icons.menu,
                      color: Theme.of(context).colorScheme.onPrimary))
              : IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: navigationBack,
                ),
          title: OnboardingContainer(
            onInitialize: (context) =>
                OnboardingContexts.instance['drawer_button'] = context,
            child: iconOnly ? SizedBox.shrink() : Text('Menu principal'),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userType == UserType.teacher)
                MenuItem(
                  title: 'Mes élèves',
                  icon: Icons.person,
                  onTap: () => RouteManager.instance.gotoStudentsPage(context),
                  iconOnly: iconOnly,
                ),
              OnboardingContainer(
                onInitialize: (context) => OnboardingContexts
                    .instance['drawer_question_button'] = context,
                child: MenuItem(
                  title: userType == UserType.teacher
                      ? 'Gestion des questions'
                      : 'Mon stage',
                  icon: Icons.speaker_notes,
                  onTap: () => userType == UserType.teacher
                      ? RouteManager.instance.gotoQAndAPage(context,
                          target: Target.all,
                          pageMode: PageMode.edit,
                          student: null)
                      : RouteManager.instance.gotoQAndAPage(context,
                          target: Target.individual,
                          pageMode: PageMode.editableView,
                          student: user),
                  iconOnly: iconOnly,
                ),
              ),
              if (userType == UserType.teacher)
                OnboardingContainer(
                  onInitialize: (context) => OnboardingContexts
                      .instance['drawer_answer_button'] = context,
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
                  onInitialize: (context) => OnboardingContexts
                      .instance['drawer_info_button'] = context,
                  child: MenuItem(
                    title: 'Ressources',
                    icon: Icons.help,
                    iconOnly: iconOnly,
                    onTap: () async {
                      await RouteManager.instance.goToResourcesPage(context);
                    },
                  ),
                ),
              if (userType == UserType.teacher)
                OnboardingContainer(
                  onInitialize: (context) => OnboardingContexts
                      .instance['drawer_feedback_button'] = context,
                  child: MenuItem(
                    title: 'Suggestions',
                    icon: Icons.feedback,
                    onTap: () => SuggestionsPage.showSuggestionPage(context),
                    iconOnly: iconOnly,
                  ),
                ),
              if (userType == UserType.teacher) const Divider(),
              MenuItem(
                title: 'Mes informations',
                icon: Icons.home,
                onTap: () => RouteManager.instance.gotoMyInfoPage(context),
                iconOnly: iconOnly,
              ),
              if (userType == UserType.teacher)
                MenuItem(
                  title: 'Revoir le tutoriel',
                  icon: Icons.help,
                  onTap: () {
                    OnboardingContexts.instance
                        .requestOnboarding(context, force: true);
                  },
                  iconOnly: iconOnly,
                ),
              if (userType == UserType.teacher) const Divider(),
              MenuItem(
                title: 'Déconnexion',
                icon: Icons.exit_to_app,
                onTap: () => Helpers.onClickQuit(context),
                iconOnly: iconOnly,
              )
            ],
          ),
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
