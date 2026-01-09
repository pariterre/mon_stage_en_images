import 'package:flutter/widgets.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/screens/all_students/students_screen.dart';
import 'package:mon_stage_en_images/screens/q_and_a/q_and_a_screen.dart';

/// The onboarding steps to be shown during the onboarding sequence
Map<String, BuildContext?> onboardingContexts = {
  'add_student': null,
  'drawer_button': null,
  'drawer_question_button': null,
  'metier_tile_0': null,
};

String? _currentPage;

Future<void> _navigateToPage(
  String pageName, {
  Target? target,
  PageMode? pageMode,
  dynamic student,
}) async {
  if (_currentPage == pageName) return;

  final context = RouteManager.instance.navigatorKey.currentContext;
  if (context == null) return;

  switch (pageName) {
    case StudentsScreen.routeName:
      await RouteManager.instance.gotoStudentsPage(context);
    case QAndAScreen.routeName:
      await RouteManager.instance.gotoQAndAPage(context,
          target: target!, pageMode: pageMode!, student: student);
    case _:
      throw Exception('Unknown page name: $pageName');
  }

  _currentPage = pageName;
}

List<OnboardingStep> onboardingSteps = [
  OnboardingStep(
    message: 'Appuyez ici pour ajouter des élèves',
    navigationCallback: (_) async {
      await _navigateToPage(StudentsScreen.routeName);
    },
    targetWidgetContext: () => onboardingContexts['add_student'],
  ),
  OnboardingStep(
    message: 'Appuyez ici pour accéder aux différentes pages de l’application.',
    navigationCallback: (_) async {
      await _navigateToPage(StudentsScreen.routeName);

      onboardingContexts['add_student']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();
    },
    targetWidgetContext: () => onboardingContexts['drawer_button'],
  ),
  OnboardingStep(
    message: 'Appuyez ici pour poser une question à vos élèves.',
    navigationCallback: (_) async {
      await _navigateToPage(StudentsScreen.routeName);

      onboardingContexts['add_student']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();
    },
    targetWidgetContext: () => onboardingContexts['drawer_question_button'],
  ),
  OnboardingStep(
    message:
        'Ici, choisissez la section M.É.T.I.E.R. associée à la question à poser',
    navigationCallback: (_) async {
      await _navigateToPage(QAndAScreen.routeName,
          target: Target.all, pageMode: PageMode.edit, student: null);

      // TODO Find why navigating does not currently work
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await onboardingContexts['metier_tile_0']
            ?.findAncestorStateOfType<QAndAScreenState>()
            ?.pageController
            .animateToPage(1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut);
      });
    },
    targetWidgetContext: () => onboardingContexts['metier_tile_0'],
  ),
  OnboardingStep(
    message: 'Vous pourrez créer une nouvelle question originale',
    navigationCallback: (_) async {
      await _navigateToPage(QAndAScreen.routeName,
          target: Target.all, pageMode: PageMode.edit, student: null);

      await Future.delayed(const Duration(milliseconds: 1000));

      final controller = onboardingContexts['metier_tile_0']
          ?.findAncestorStateOfType<QAndAScreenState>()
          ?.pageController;
      debugPrint(controller.toString());
      await onboardingContexts['metier_tile_0']
          ?.findAncestorStateOfType<QAndAScreenState>()
          ?.pageController
          .animateToPage(1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut);
    },
  ),
  OnboardingStep(
    message: 'Ou en choisir une déjà créée et la modifier',
    navigationCallback: (_) async {
      await _navigateToPage(QAndAScreen.routeName,
          target: Target.all, pageMode: PageMode.edit, student: null);

      await onboardingContexts['metier_tile_0']
          ?.findAncestorStateOfType<QAndAScreenState>()
          ?.pageController
          .animateToPage(1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut);
    },
  ),
  OnboardingStep(
    message:
        'Sur cette page, vous verrez toutes les réponses à une même question.',
    navigationCallback: (_) async {
      await _navigateToPage(StudentsScreen.routeName);

      onboardingContexts['add_student']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();
    },
  ),
  OnboardingStep(
    message: 'Vous trouverez ici davantage d\'informations et du support.',
    navigationCallback: (_) async {
      await _navigateToPage(StudentsScreen.routeName);

      onboardingContexts['add_student']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();
    },
  ),
];
