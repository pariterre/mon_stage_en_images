import 'package:flutter/widgets.dart';
import 'package:mon_stage_en_images/screens/login/wrong_version_screen.dart';
import 'package:mon_stage_en_images/screens/login/go_to_irsst_screen.dart';
import 'package:mon_stage_en_images/screens/login/login_screen.dart';
import 'package:mon_stage_en_images/screens/login/terms_and_services_screen.dart';

/// This is a navigation observer for deciding whether the currentRoute
/// is a valid entry point for the onboarding sequence.
/// It contains some redundancy checks for defaults route on purpose, which are also achieved by
/// the method in onGeneratedInitialRoute parameter of MaterialApp in main.
/// These checks should not be removed to prevent unflagged bugs during the login process
/// if the onGenerateInitialRoute parameter were to be changed later.

class OnboardingNavigatorObserver extends NavigatorObserver
    with ChangeNotifier {
  OnboardingNavigatorObserver._();

  static OnboardingNavigatorObserver get instance => _instance;
  static final _instance = OnboardingNavigatorObserver._();

  /// This list contains every route that should be ignore by the navigation observer
  /// when it comes to decide whether or not the observed route is a valid entry point
  /// for the onboarding.
  final List<String?> routeExclusionList = [
    LoginScreen.routeName,
    TermsAndServicesScreen.routeName,
    GoToIrsstScreen.routeName,
    WrongVersionScreen.routeName,
    // Ignoring the first 'null' route when initializing the app
    // Another redundant check is present in _reactToNavigationEvent
    // To achieve similar goal
    null,
    // Default initialRoute excluded. OnGeneratedInitialRoute override in main
    // Is a redudant protection but please keep this list entry if OnGeneratedInitialRoute
    // Were to be changed later.
    '/'
  ];

  bool get isRouteIncluded => !routeExclusionList.contains(currentRouteName);

  ModalRoute? _currentRoute;
  ModalRoute? get currentRoute => _currentRoute;
  String? get currentRouteName => _currentRoute?.settings.name;

  final ValueNotifier<AnimationStatus?> animationStatus =
      ValueNotifier(AnimationStatus.completed);

  void setAnimationStatus(AnimationStatus status) {
    animationStatus.value = status;
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _reactToNavigationEvent(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != oldRoute) _reactToNavigationEvent(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _reactToNavigationEvent(route);
    super.didPop(route, previousRoute);
  }

  void _reactToNavigationEvent(Route? route) {
    if (route is! PageRoute) return;

    _currentRoute = route;
    notifyListeners();
  }
}
