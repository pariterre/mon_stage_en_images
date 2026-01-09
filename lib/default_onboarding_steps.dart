import 'package:flutter/widgets.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/screens/all_students/students_screen.dart';
import 'package:mon_stage_en_images/screens/q_and_a/q_and_a_screen.dart';

/// The onboarding steps to be shown during the onboarding sequence
Map<String, BuildContext?> onboardingKeys = {
  'add_student': null,
  'drawer_button': null,
};

List<OnboardingStep> onboardingSteps = [
  OnboardingStep(
    message: 'Appuyez ici pour ajouter des élèves',
    navigationCallback: (_) async {
      final context = RouteManager.instance.navigatorKey.currentContext;
      if (context == null) return;

      await RouteManager.instance.gotoStudentsPage(context);
    },
    targetWidgetContext: () => onboardingKeys['add_student'],
  ),
  OnboardingStep(
    message: 'Appuyez ici pour accéder aux différentes pages de l’application.',
    navigationCallback: (_) async {
      onboardingKeys['add_student']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();
    },
    targetWidgetContext: () => onboardingKeys['drawer_button'],
  ),
  OnboardingStep(
    message: 'Appuyez ici pour poser une question à vos élèves.',
    navigationCallback: (_) async {
      final context = RouteManager.instance.navigatorKey.currentContext;
      if (context == null) return;

      await RouteManager.instance.gotoStudentsPage(context);
      if (!context.mounted) return;

      final state = RouteManager.instance.navigatorKey.currentState;
      (state as StudentsScreenState).openDrawer();
    },
  ),
  OnboardingStep(
    message:
        'Ici, choisissez la section M.É.T.I.E.R. associée à la question à poser',
    navigationCallback: (_) async {
      final context = RouteManager.instance.navigatorKey.currentContext;
      if (context == null) return;

      await RouteManager.instance.gotoQAndAPage(context,
          target: Target.all, pageMode: PageMode.edit, student: null);
      if (!context.mounted) return;

      final state = RouteManager.instance.navigatorKey.currentState;
      QAndAScreen.animateTo(state as State<QAndAScreen>, 0);
    },
  ),
  OnboardingStep(
    message: 'Vous pourrez créer une nouvelle question originale',
    navigationCallback: (_) async {
      final context = RouteManager.instance.navigatorKey.currentContext;
      if (context == null) return;

      await RouteManager.instance.gotoQAndAPage(context,
          target: Target.all, pageMode: PageMode.edit, student: null);
      if (!context.mounted) return;

      final state = RouteManager.instance.navigatorKey.currentState;
      QAndAScreen.animateTo(state as State<QAndAScreen>, 1);
    },
  ),
  OnboardingStep(
    message: 'Ou en choisir une déjà créée et la modifier',
    navigationCallback: (_) async {
      final context = RouteManager.instance.navigatorKey.currentContext;
      if (context == null) return;

      await RouteManager.instance.gotoQAndAPage(context,
          target: Target.all, pageMode: PageMode.edit, student: null);
      if (!context.mounted) return;

      final state = RouteManager.instance.navigatorKey.currentState;
      QAndAScreen.animateTo(state as State<QAndAScreen>, 1);
    },
  ),
  OnboardingStep(
    message:
        'Sur cette page, vous verrez toutes les réponses à une même question.',
    navigationCallback: (_) async {
      final context = RouteManager.instance.navigatorKey.currentContext;
      if (context == null) return;

      await RouteManager.instance.gotoStudentsPage(context);
      if (!context.mounted) return;

      final state = RouteManager.instance.navigatorKey.currentState;
      (state as StudentsScreenState).openDrawer();
    },
  ),
  OnboardingStep(
    message: 'Vous trouverez ici davantage d\'informations et du support.',
    navigationCallback: (_) async {
      final context = RouteManager.instance.navigatorKey.currentContext;
      if (context == null) return;

      await RouteManager.instance.gotoStudentsPage(context);
      if (!context.mounted) return;

      final state = RouteManager.instance.navigatorKey.currentState;
      (state as StudentsScreenState).openDrawer();
    },
  ),
];
