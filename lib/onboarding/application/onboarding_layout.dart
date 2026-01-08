import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/onboarding/application/onboarding_keys_service.dart';
import 'package:mon_stage_en_images/onboarding/application/onboarding_observer.dart';
import 'package:mon_stage_en_images/onboarding/data/onboarding_steps_list.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/onboarding/widgets/onboarding_dialog_with_highlight.dart';
import 'package:provider/provider.dart';

final _logger = Logger('OnboardingLayout');

/// Main orchestrator for the Onboarding feature. Listens to conditions for showing the onboarding sequence
/// and manages both the navigation to the current target and the arguments passing to the onboarding overlay dialog.
class OnboardingLayout extends StatefulWidget {
  const OnboardingLayout({
    super.key,
    required this.child,
    required this.onBoardingSteps,
  });

  final Widget child;
  final List<OnboardingStep> onBoardingSteps;

  @override
  State<OnboardingLayout> createState() => _OnboardingLayoutState();
}

class _OnboardingLayoutState extends State<OnboardingLayout> {
  int? _currentIndex;

  OnboardingStep? get current {
    if (_currentIndex == null) return null;
    return _checkShowTutorial() ? onboardingSteps[_currentIndex!] : null;
  }

  bool _checkShowTutorial() {
    if (!OnboardingNavigatorObserver.instance.isRouteIncluded) return false;

    final currentUser =
        Provider.of<Database>(context, listen: false).currentUser;
    if (currentUser?.userType != UserType.teacher ||
        !currentUser!.termsAndServicesAccepted) {
      return false;
    }

    final sharedPrefs = SharedPreferencesManager.instance;
    if (sharedPrefs.hasSeenOnboarding ||
        !sharedPrefs.hasAlreadySeenTheIrrstPage) {
      return false;
    }

    return true;
  }

  void _increment() {
    if (_currentIndex == null) return;
    _currentIndex = _currentIndex! + 1;
  }

  void _decrement() {
    if (_currentIndex == null || _currentIndex! < 1) return;
    _currentIndex = _currentIndex! - 1;
  }

  void _resetIndex() {
    _currentIndex = onboardingSteps.isNotEmpty ? 0 : null;
  }

  Future<void> _next() async {
    if (_currentIndex == null) return;
    if (_currentIndex! < widget.onBoardingSteps.length - 1) {
      _increment();
      _navToStepAndRefresh();
    } else {
      _complete();
    }
  }

  Future<void> _previous() async {
    if (_currentIndex == null) return;
    if (_currentIndex! > 0) {
      _decrement();
      _navToStepAndRefresh();
    }
  }

  /// Ends the onboarding sequence by writing in local storage that onboarding has been shown.
  /// Resets the onboarding sequence to allow another run
  Future<void> _complete() async {
    _logger.finest('_complete is running');
    SharedPreferencesManager.instance.hasSeenOnboarding = true;
    _resetIndex();
  }

  @override
  void initState() {
    OnboardingNavigatorObserver.instance.addListener(_navToStepAndRefresh);
    SharedPreferencesManager.instance.addListener(_navToStepAndRefresh);

    _resetIndex();
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    _logger.finest('didChangeDependencies running in _OnBoardingLayout');

    _resetIndex();

    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => _navToStepAndRefresh());
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    OnboardingNavigatorObserver.instance.removeListener(_navToStepAndRefresh);
    SharedPreferencesManager.instance.removeListener(_navToStepAndRefresh);
    super.dispose();
  }

  /// Navigates to screen based on the index provided if needed. Then, it prepares the screen to actually
  /// display the targeted widget
  void _navToStepAndRefresh() =>
      _navToStep().whenComplete(() => setState(() {}));

  Future<void> _navToStep() async {
    _logger.finest('_navToStep : running');

    // Checking if our step is null and if we should flag its index as inactive
    final step = current;
    if (step == null) {
      _logger.finest('_navToStep : will return because currentStep is null');
      return;
    }
    // Navigating to the OnboardingStep Widget's route.
    try {
      final currentRoute =
          OnboardingNavigatorObserver.instance.currentRouteName;

      _logger.finest(
          '_navToStep : currentRoute is $currentRoute  and step.routeName is ${step.routeName}');
      // We want to navigate only if we are not already on the desired route.
      // If we are on the first step, we always want to navigate to this screen's step.
      if (currentRoute != step.routeName || _currentIndex == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // TODO Change this
          RouteManager.instance.navigatorKey.currentState
              ?.pushReplacementNamed(step.routeName, arguments: step.arguments)
              .then(
                (value) => _logger.finest(
                    '_navToStep : after navigation with rootNavigatorKey, $value'),
              );
        });
      }
    } catch (e, st) {
      _logger.severe(
          '_navToStep : error on _navToStep navigation : ${e.toString()} $st');
      _resetIndex();
    }

    // Maybe our targeted widget is not mounted yet and required additional actions
    // Like opening a drawer or using a pagecontroller. We will check if this is needed.
    await _shouldPrepareOnboardingTargetDisplay(step);

    final targetKey = await _waitForTargetKeyRegistration(step.targetId);
    _logger
        .finest('Looking for key with id=${step.targetId}, got key=$targetKey');

    // Waiting for the widget context to be available
    if (targetKey == null) {
      _logger.warning(
          'cannot find Key in Onboarding service, key is null, resetting index');
      _resetIndex();
    }
    final widgetContext =
        await _tryGiveWidgetContextWhenAvalaible(key: targetKey);

    if (widgetContext == null) {
      _logger.severe('cannot obtain widgetContext for id=${step.targetId}');
      _resetIndex();
    }
  }

  /// Checks if further actions are needed after navigation to display the targeted widget.
  /// Performs required actions to allow the targeted widget to be mounted inside the tree,
  /// through the prepareNav parameter of the provided OnboardingStep
  Future<void> _shouldPrepareOnboardingTargetDisplay(
    OnboardingStep step,
  ) async {
    // Maybe our targeted widget is not mounted yet and required additional actions
    // Like opening a drawer or using a pagecontroller.
    // So we use the GlobalKey<State<StatefulWidget>> declared for the widget by onGenerateRoute
    // to get a valid context

    _logger.finest(
        '_shouldPrepareOnboardingTargetDisplay : will attempt to get key for prepareNav');

    // Retrieves the GlobalKey<State<StatefulWidget> registered for this screen upon navigation.
    // This key can be used to obtain the State and performs actions like opening drawers, jumping in a page view, ...
    final key = RouteManager.instance.currentScreenKey!;

    // Waiting for the State of the screen
    final State<StatefulWidget>? state =
        await _waitForScreenState(key).then((value) {
      _logger.finest(
          '_shouldPrepareOnboardingTargetDisplay : state for prepareNav is $value');
      return value;
    });
    _logger.finest(
        '_shouldPrepareOnboardingTargetDisplay : will try to prepareNav');
    if (state == null) {
      _logger.info(
          '_shouldPrepareOnboardingTargetDisplay : state is null after _waitforScreenState, will return');
      return;
    }
    step.prepareNav == null
        // No prepareNav was provided by the step, we still want to reset scaffold state
        // to prevent conflicts when displaying our overlay : our targeted widget may be under a scaffold element,
        // like a drawer and wouldn't be visible otherwise
        ? await _tryGiveWidgetContextWhenAvalaible(key: key).then(
            (value) {
              _logger.finest('value is $value');
              if (value != null && value.mounted) {
                step.resetScaffoldElements(value, state);
              }
            },
          )
        // A prepareNav was provided by the step, we will run it.
        : await step.prepareNav!(null, state);
  }

  Future<BuildContext?> _tryGiveWidgetContextWhenAvalaible({
    required GlobalKey? key,
    int timeout = 2000,
  }) async {
    if (key == null) return Future.value(null);

    final completer = Completer<BuildContext?>();
    final start = DateTime.now();

    void checkFuture() {
      final widgetContext = key.currentContext;
      if (widgetContext != null) {
        if (!completer.isCompleted) completer.complete(widgetContext);
        return;
      }
      final elapsed = DateTime.now().difference(start).inMilliseconds;

      // If we outreach our timer limit,
      // then we give up and return a null instead of context
      if (elapsed >= timeout) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      // If we still have time, we check again in the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => checkFuture());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => checkFuture());
    return completer.future;
  }

  Future<GlobalKey<State<StatefulWidget>>?> _waitForTargetKeyRegistration(
      String targetKeyId,
      {int timeoutMs = 2000}) async {
    final completer = Completer<GlobalKey?>();
    final start = DateTime.now();

    void check() {
      final key =
          OnboardingKeysService.instance.findTargetKeyWithId(targetKeyId);
      if (key != null) {
        completer.complete(key);
        return;
      }
      if (DateTime.now().difference(start).inMilliseconds > timeoutMs) {
        completer.complete(null);
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => check());
    }

    check();
    return completer.future;
  }

  Future<State<StatefulWidget>?> _waitForScreenState(
      GlobalKey<State<StatefulWidget>> key,
      {int timeoutMs = 2000}) async {
    final completer = Completer<State<StatefulWidget>?>();
    final start = DateTime.now();

    void check() {
      final state = key.currentState;
      if (state != null) {
        completer.complete(state);
        return;
      }
      if (DateTime.now().difference(start).inMilliseconds > timeoutMs) {
        completer.complete(null);
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => check());
    }

    check();
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser =
        Provider.of<Database>(context, listen: false).currentUser;
    final sharedPrefs = SharedPreferencesManager.instance;

    _logger.finer(
        'OnboardingLayout build : _currentUser is $currentUser | _hasSeenOnboarding is ${sharedPrefs.hasSeenOnboarding} ');
    _logger.finer(
        '| _hasAlreadySeenTheIrrstPage is ${sharedPrefs.hasAlreadySeenTheIrrstPage} | _currentUser!.termsAndServicesAccepted is ${currentUser?.termsAndServicesAccepted}');
    _logger.finer(
        '| isValidScreenToShowTutorial is ${OnboardingNavigatorObserver.instance.isRouteIncluded}');
    _logger.finer('build : showTutorial is ${_checkShowTutorial()}');

    return Stack(children: [
      widget.child,
      if (current != null)
        OnboardingDialogWithHighlight(
            key: ValueKey(current!.targetId),
            complete: _complete,
            onboardingStep: current,
            onForward: () {
              _next();
            },
            onBackward: _currentIndex! > 0
                ? () {
                    _previous();
                  }
                : null),
    ]);
  }
}
