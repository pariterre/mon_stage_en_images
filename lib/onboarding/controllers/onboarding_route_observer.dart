import 'package:flutter/widgets.dart';

/// This is a navigation observer for deciding whether the currentRoute
/// is a valid entry point for the onboarding sequence.
/// It contains some redundancy checks for defaults route on purpose, which are also achieved by
/// the method in onGeneratedInitialRoute parameter of MaterialApp in main.
/// These checks should not be removed to prevent unflagged bugs during the login process
/// if the onGenerateInitialRoute parameter were to be changed later.

class OnboardingRouteObserver extends NavigatorObserver with ChangeNotifier {
  OnboardingRouteObserver();

  ModalRoute? _currentRoute;
  ModalRoute? get currentRoute => _currentRoute;
  String? get currentRouteName => _currentRoute?.settings.name;
  BuildContext? get currentContext => _currentRoute?.subtreeContext;

  @override
  void didPush(Route route, Route? previousRoute) {
    _reactToNavigationEvent(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute?.settings.name != oldRoute?.settings.name) {
      _reactToNavigationEvent(newRoute);
    }
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
