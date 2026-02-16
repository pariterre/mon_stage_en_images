import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/providers/database.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/onboarding/widgets/onboarding_overlay.dart';
import 'package:mon_stage_en_images/screens/all_students/students_screen.dart';
import 'package:mon_stage_en_images/screens/q_and_a/q_and_a_screen.dart';
import 'package:mon_stage_en_images/screens/resources/resources_screen.dart';
import 'package:provider/provider.dart';

class OnboardingContexts {
  // Singleton pattern
  OnboardingContexts._();
  static final OnboardingContexts instance = OnboardingContexts._();

  bool _isInitialized = false;
  Future<void> initialize({required OnboardingController controller}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _controller = controller;
  }

  OnboardingController? _controller;
  bool get isOnboarding => _controller?.isOnboarding ?? false;

  User get dummyStudent => User.publicUser(
      id: 'dummy', firstName: 'Mon élève', lastName: 'du PFAE', avatar: '🐸');

  void requestOnboarding(BuildContext context, {bool force = false}) {
    if (!_isInitialized) {
      throw Exception(
          'OnboardingContexts must be initialized before requesting onboarding.');
    }
    if (!_startingConditionAreMet(context, force: force)) return;

    _controller!.requestOnboarding();
  }

  bool _startingConditionAreMet(BuildContext context, {required bool force}) {
    if (!_isInitialized) {
      throw Exception(
          'OnboardingContexts must be initialized before checking starting conditions.');
    }

    final database = Provider.of<Database>(context, listen: false);
    final userType = database.userType;
    final user = database.currentUser;

    return !_controller!.isOnboarding &&
        userType == UserType.teacher &&
        (force || (user != null && !user.hasSeenTeacherOnboarding));
  }

  /// The onboarding steps to be shown during the onboarding sequence
  final _onboardingContexts = <String, Map<String, BuildContext?>>{
    StudentsScreen.routeName: {
      'generate_code': null,
      'more_options_student_button': null,
      'drawer_button': null,
      'drawer_question_button': null,
      'drawer_answer_button': null,
      'drawer_feedback_button': null,
    },
    QAndAScreen.routeName: {
      'q_and_a_app_bar_title': null,
      'metier_tile_0': null,
      'new_question_button': null,
      'all_question_buttons': null,
    },
    ResourcesScreen.routeName: {
      'resources_body': null,
      'drawer_info_button': null,
    }
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

  Future<void> prepareForOnboarding() async {
    if (!_isInitialized) {
      throw Exception(
          'OnboardingContexts must be initialized before preparing for onboarding.');
    }

    OnboardingContexts.instance._currentPage = null;
    OnboardingContexts.instance._isNavigating = true;
    await _navigateToPage(StudentsScreen.routeName, force: true);
    OnboardingContexts.instance._isNavigating = false;
  }

  Future<void> finilizeOnboarding() async {
    if (!_isInitialized) {
      throw Exception(
          'OnboardingContexts must be initialized before preparing for onboarding.');
    }

    OnboardingContexts.instance._isNavigating = true;
    await _navigateToPage(StudentsScreen.routeName, force: true);

    while (OnboardingContexts.instance['generate_code'] == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    OnboardingContexts.instance['generate_code']
        ?.findAncestorStateOfType<StudentsScreenState>()
        ?.closeDrawer();

    OnboardingContexts.instance._isNavigating = false;
  }

  List<OnboardingStep> onboardingSteps = [
    OnboardingStep(
      message:
          'Appuyez ici pour générer un code d\'inscription pour vos élèves.',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;
        await _navigateToPage(StudentsScreen.routeName);
        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () => OnboardingContexts.instance['generate_code'],
    ),
    OnboardingStep(
        message:
            'Appuyez ici pour écrire une note privée sur un élève ou le supprimer',
        navigationCallback: (_) async {
          OnboardingContexts.instance._isNavigating = true;
          await _navigateToPage(StudentsScreen.routeName);
          OnboardingContexts.instance._isNavigating = false;
        },
        targetWidgetContext: () =>
            OnboardingContexts.instance['more_options_student_button']),
    OnboardingStep(
      message:
          'Appuyez ici pour accéder aux différentes pages de l\'application.',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;

        await _navigateToPage(StudentsScreen.routeName);

        while (OnboardingContexts.instance['generate_code'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        OnboardingContexts.instance['generate_code']
            ?.findAncestorStateOfType<StudentsScreenState>()
            ?.openDrawer();
        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () => OnboardingContexts.instance['drawer_button'],
    ),
    OnboardingStep(
      message: 'Appuyez ici pour poser une question à vos élèves.',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;
        await _navigateToPage(StudentsScreen.routeName);

        while (OnboardingContexts.instance['generate_code'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        OnboardingContexts.instance['generate_code']
            ?.findAncestorStateOfType<StudentsScreenState>()
            ?.openDrawer();

        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () =>
          OnboardingContexts.instance['drawer_question_button'],
    ),
    OnboardingStep(
      message:
          'Ici, choisissez la section M.É.T.I.E.R. associée à la question à poser',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;
        await _navigateToPage(QAndAScreen.routeName,
            target: Target.all, pageMode: PageMode.edit, student: null);

        while (OnboardingContexts.instance['q_and_a_app_bar_title'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await OnboardingContexts.instance['q_and_a_app_bar_title']
            ?.findAncestorStateOfType<QAndAScreenState>()
            ?.onPageChangedRequest(-1);

        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () {
        if (OnboardingContexts.instance._isNavigating) return null;
        return OnboardingContexts.instance['metier_tile_0'];
      },
    ),
    OnboardingStep(
      message: 'Vous pourrez créer une nouvelle question originale',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;
        await _navigateToPage(QAndAScreen.routeName,
            target: Target.all, pageMode: PageMode.edit, student: null);

        while (OnboardingContexts.instance['q_and_a_app_bar_title'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await OnboardingContexts.instance['q_and_a_app_bar_title']
            ?.findAncestorStateOfType<QAndAScreenState>()
            ?.onPageChangedRequest(0);
        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () =>
          OnboardingContexts.instance['new_question_button'],
    ),
    OnboardingStep(
      message: 'Ou en choisir une déjà créée et la modifier',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;
        await _navigateToPage(QAndAScreen.routeName,
            target: Target.all, pageMode: PageMode.edit, student: null);

        while (OnboardingContexts.instance['q_and_a_app_bar_title'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await OnboardingContexts.instance['q_and_a_app_bar_title']
            ?.findAncestorStateOfType<QAndAScreenState>()
            ?.onPageChangedRequest(0);
        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () =>
          OnboardingContexts.instance['all_question_buttons'],
    ),
    OnboardingStep(
      message:
          'Sur cette page, vous verrez toutes les réponses à une même question.',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;
        await _navigateToPage(StudentsScreen.routeName);

        while (OnboardingContexts.instance['generate_code'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        OnboardingContexts.instance['generate_code']
            ?.findAncestorStateOfType<StudentsScreenState>()
            ?.openDrawer();

        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () =>
          OnboardingContexts.instance['drawer_answer_button'],
    ),
    OnboardingStep(
      message: 'Vous trouverez ici davantage d\'informations et du support.',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;
        await _navigateToPage(ResourcesScreen.routeName);

        while (OnboardingContexts.instance['resources_body'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        OnboardingContexts.instance['resources_body']
            ?.findAncestorStateOfType<ResourcesScreenState>()
            ?.openDrawer();

        while (OnboardingContexts.instance['drawer_info_button'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () =>
          OnboardingContexts.instance['drawer_info_button'],
    ),
    OnboardingStep(
      message:
          'Utilisez le formulaire accessible ici pour nous transmettre vos suggestions',
      navigationCallback: (_) async {
        OnboardingContexts.instance._isNavigating = true;
        await _navigateToPage(StudentsScreen.routeName);

        while (OnboardingContexts.instance['generate_code'] == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        OnboardingContexts.instance['generate_code']
            ?.findAncestorStateOfType<StudentsScreenState>()
            ?.openDrawer();

        OnboardingContexts.instance._isNavigating = false;
      },
      targetWidgetContext: () =>
          OnboardingContexts.instance['drawer_feedback_button'],
    ),
  ];
}

Future<void> _navigateToPage(
  String pageName, {
  Target? target,
  PageMode? pageMode,
  dynamic student,
  bool force = false,
}) async {
  if (!force && OnboardingContexts.instance._currentPage == pageName) return;
  OnboardingContexts.instance._currentPage = pageName;

  final context = RouteManager.instance.navigatorKey.currentContext;
  if (context == null) return;

  switch (pageName) {
    case StudentsScreen.routeName:
      RouteManager.instance.gotoStudentsPage(context);
    case QAndAScreen.routeName:
      RouteManager.instance.gotoQAndAPage(context,
          target: target!, pageMode: pageMode!, student: student);
    case ResourcesScreen.routeName:
      RouteManager.instance.goToResourcesPage(context);
    case _:
      throw Exception('Unknown page name: $pageName');
  }
}
