import 'package:flutter/widgets.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/screens/all_students/students_screen.dart';
import 'package:mon_stage_en_images/screens/q_and_a/q_and_a_screen.dart';

class OnboardingContexts {
  /// The onboarding steps to be shown during the onboarding sequence
  final _onboardingContexts = <String, Map<String, BuildContext?>>{
    StudentsScreen.routeName: {
      'generate_code': null,
      'drawer_button': null,
      'drawer_question_button': null,
      'drawer_answer_button': null,
      'drawer_info_button': null,
    },
    QAndAScreen.routeName: {
      'q_and_a_app_bar_title': null,
      'metier_tile_0': null,
      'new_question_button': null,
      'all_question_buttons': null,
    },
  };

  void operator []=(String key, BuildContext? context) {
    // Preventing from writting when not onboarding
    if (_onboardingContexts[_currentPage]?.containsKey(key) != true) return;
    _onboardingContexts[_currentPage]?[key] = context;
  }

  BuildContext? operator [](String key) =>
      _onboardingContexts[_currentPage]?[key]?.mounted == true
          ? _onboardingContexts[_currentPage]![key]
          : null;

  String? _currentPage;
  bool _isNavigating = false;
}

final onboardingContexts = OnboardingContexts();

Future<void> _navigateToPage(
  String pageName, {
  Target? target,
  PageMode? pageMode,
  dynamic student,
}) async {
  if (onboardingContexts._currentPage == pageName) return;
  onboardingContexts._currentPage = pageName;

  final context = RouteManager.instance.navigatorKey.currentContext;
  if (context == null) return;

  switch (pageName) {
    case StudentsScreen.routeName:
      RouteManager.instance.gotoStudentsPage(context);
    case QAndAScreen.routeName:
      RouteManager.instance.gotoQAndAPage(context,
          target: target!, pageMode: pageMode!, student: student);
    case _:
      throw Exception('Unknown page name: $pageName');
  }
}

List<OnboardingStep> onboardingSteps = [
  OnboardingStep(
    message: 'Appuyez ici pour générer un code d\'inscription pour vos élèves.',
    navigationCallback: (_) async {
      onboardingContexts._isNavigating = true;
      await _navigateToPage(StudentsScreen.routeName);
      onboardingContexts._isNavigating = false;
    },
    targetWidgetContext: () => onboardingContexts['generate_code'],
  ),
  OnboardingStep(
    message: 'Appuyez ici pour accéder aux différentes pages de l’application.',
    navigationCallback: (_) async {
      onboardingContexts._isNavigating = true;
      await _navigateToPage(StudentsScreen.routeName);

      while (onboardingContexts['generate_code'] == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      onboardingContexts['generate_code']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();
      onboardingContexts._isNavigating = false;
    },
    targetWidgetContext: () => onboardingContexts['drawer_button'],
  ),
  OnboardingStep(
    message: 'Appuyez ici pour poser une question à vos élèves.',
    navigationCallback: (_) async {
      onboardingContexts._isNavigating = true;
      await _navigateToPage(StudentsScreen.routeName);

      while (onboardingContexts['generate_code'] == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      onboardingContexts['generate_code']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();

      onboardingContexts._isNavigating = false;
    },
    targetWidgetContext: () => onboardingContexts['drawer_question_button'],
  ),
  OnboardingStep(
    message:
        'Ici, choisissez la section M.É.T.I.E.R. associée à la question à poser',
    navigationCallback: (_) async {
      onboardingContexts._isNavigating = true;
      await _navigateToPage(QAndAScreen.routeName,
          target: Target.all, pageMode: PageMode.edit, student: null);

      while (onboardingContexts['q_and_a_app_bar_title'] == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await onboardingContexts['q_and_a_app_bar_title']
          ?.findAncestorStateOfType<QAndAScreenState>()
          ?.onPageChangedRequest(-1);

      onboardingContexts._isNavigating = false;
    },
    targetWidgetContext: () {
      if (onboardingContexts._isNavigating) return null;
      return onboardingContexts['metier_tile_0'];
    },
  ),
  OnboardingStep(
    message: 'Vous pourrez créer une nouvelle question originale',
    navigationCallback: (_) async {
      onboardingContexts._isNavigating = true;
      await _navigateToPage(QAndAScreen.routeName,
          target: Target.all, pageMode: PageMode.edit, student: null);

      while (onboardingContexts['q_and_a_app_bar_title'] == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await onboardingContexts['q_and_a_app_bar_title']
          ?.findAncestorStateOfType<QAndAScreenState>()
          ?.onPageChangedRequest(0);
      onboardingContexts._isNavigating = false;
    },
    targetWidgetContext: () => onboardingContexts['new_question_button'],
  ),
  OnboardingStep(
    message: 'Ou en choisir une déjà créée et la modifier',
    navigationCallback: (_) async {
      onboardingContexts._isNavigating = true;
      await _navigateToPage(QAndAScreen.routeName,
          target: Target.all, pageMode: PageMode.edit, student: null);

      while (onboardingContexts['q_and_a_app_bar_title'] == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await onboardingContexts['q_and_a_app_bar_title']
          ?.findAncestorStateOfType<QAndAScreenState>()
          ?.onPageChangedRequest(0);
      onboardingContexts._isNavigating = false;
    },
    targetWidgetContext: () => onboardingContexts['all_question_buttons'],
  ),
  OnboardingStep(
    message:
        'Sur cette page, vous verrez toutes les réponses à une même question.',
    navigationCallback: (_) async {
      onboardingContexts._isNavigating = true;
      await _navigateToPage(StudentsScreen.routeName);

      while (onboardingContexts['generate_code'] == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      onboardingContexts['generate_code']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();

      onboardingContexts._isNavigating = false;
    },
    targetWidgetContext: () => onboardingContexts['drawer_answer_button'],
  ),
  OnboardingStep(
    message: 'Vous trouverez ici davantage d\'informations et du support.',
    navigationCallback: (_) async {
      onboardingContexts._isNavigating = true;
      await _navigateToPage(StudentsScreen.routeName);

      while (onboardingContexts['generate_code'] == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      onboardingContexts['generate_code']
          ?.findAncestorStateOfType<StudentsScreenState>()
          ?.openDrawer();

      onboardingContexts._isNavigating = false;
    },
    targetWidgetContext: () => onboardingContexts['drawer_info_button'],
  ),
];
