import 'package:flutter/widgets.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/screens/all_students/students_screen.dart';
import 'package:mon_stage_en_images/screens/q_and_a/q_and_a_screen.dart';

/// The onboarding steps to be shown during the onboarding sequence
List<OnboardingStep> onboardingSteps = [
  OnboardingStep(
      title: 'Add student',
      routeName: StudentsScreen.routeName,
      message: 'Appuyez ici pour ajouter des élèves'),
  OnboardingStep(
      title: 'Drawer',
      routeName: StudentsScreen.routeName,
      message:
          'Appuyez ici pour accéder aux différentes pages de l’application.'),
  OnboardingStep(
    title: 'Drawer opened',
    routeName: StudentsScreen.routeName,
    message: 'Appuyez ici pour poser une question à vos élèves.',
    prepareNav: (context, outsideState) async {
      final state = outsideState as StudentsScreenState;
      if (state.isDrawerOpen == false) state.openDrawer();
    },
  ),
  OnboardingStep(
      title: 'Metier',
      routeName: QAndAScreen.routeName,
      arguments: [Target.all, PageMode.edit, null],
      prepareNav:
          (BuildContext? context, State<StatefulWidget>? outsideState) async {
        final state = outsideState as State<QAndAScreen>;
        QAndAScreen.onPageChangedRequestFromOutside(state, 0);
      },
      message:
          'Ici, choisissez la section M.É.T.I.E.R. associée à la question à poser'),
  OnboardingStep(
      title: 'New question',
      routeName: QAndAScreen.routeName,
      arguments: [Target.all, PageMode.edit, null],
      prepareNav:
          (BuildContext? context, State<StatefulWidget>? outsideState) async {
        final state = outsideState as State<QAndAScreen>;
        QAndAScreen.onPageChangedRequestFromOutside(state, 1);
      },
      message: 'Vous pourrez créer une nouvelle question originale'),
  OnboardingStep(
      title: 'Example questions',
      routeName: QAndAScreen.routeName,
      arguments: [Target.all, PageMode.edit, null],
      prepareNav:
          (BuildContext? context, State<StatefulWidget>? outsideState) async {
        final state = outsideState as State<QAndAScreen>;
        QAndAScreen.onPageChangedRequestFromOutside(state, 1);
      },
      message: 'Ou en choisir une déjà créée et la modifier'),
  OnboardingStep(
    title: 'Questions summary',
    routeName: StudentsScreen.routeName,
    message:
        'Sur cette page, vous verrez toutes les réponses à une même question.',
    prepareNav: (context, outsideState) async {
      final state = outsideState as StudentsScreenState;
      if (state.isDrawerOpen == false) state.openDrawer();
    },
  ),
  OnboardingStep(
    title: 'Learn more',
    routeName: StudentsScreen.routeName,
    message: 'Vous trouverez ici davantage d\'informations et du support.',
    prepareNav: (context, outsideState) async {
      final state = outsideState as StudentsScreenState;
      if (state.isDrawerOpen == false) state.openDrawer();
    },
  ),
];
