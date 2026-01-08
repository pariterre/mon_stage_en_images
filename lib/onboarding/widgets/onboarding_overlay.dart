import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mon_stage_en_images/onboarding/controllers/onboarding_route_observer.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/onboarding/widgets/onboarding_dialog.dart';

final _logger = Logger('OnboardingLayout');

class OnboardingController {
  final List<OnboardingStep> steps;

  OnboardingController({
    required this.steps,
    required this.getCurrentScreenKey,
    required this.getNavigatorState,
    required this.shouldShowTutorial,
    required this.onOnboardingComplete,
  });

  final observer = OnboardingRouteObserver();

  final GlobalKey<State<StatefulWidget>>? Function() getCurrentScreenKey;
  final NavigatorState? Function() getNavigatorState;
  final bool Function(BuildContext context) shouldShowTutorial;
  final VoidCallback onOnboardingComplete;

  _OnboardingOverlayState? _overlayState;
  void requestOnboarding() {
    if (_overlayState?.currentStep == null) {
      _overlayState?._resetIndex();
      _overlayState?._navToStepAndRefresh();
    }
  }
}

/// Main orchestrator for the Onboarding feature. Listens to conditions for showing the onboarding sequence
/// and manages both the navigation to the current target and the arguments passing to the onboarding overlay dialog.
class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final OnboardingController controller;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int? _currentIndex;

  OnboardingStep? get currentStep {
    if (_currentIndex == null ||
        !widget.controller.shouldShowTutorial(context)) {
      return null;
    }
    return widget.controller.steps[_currentIndex!];
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
    _currentIndex = widget.controller.steps.isNotEmpty ? 0 : null;
  }

  Future<void> _next() async {
    if (_currentIndex == null) return;
    if (_currentIndex! < widget.controller.steps.length - 1) {
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
    widget.controller.onOnboardingComplete();
    _resetIndex();
  }

  @override
  void initState() {
    widget.controller.observer.addListener(() => _navToStepAndRefresh());
    widget.controller._overlayState = this;

    _resetIndex();
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.observer.removeListener(() => _navToStepAndRefresh());
    super.dispose();
  }

  /// Navigates to screen based on the index provided if needed. Then, it prepares the screen to actually
  /// display the targeted widget
  void _navToStepAndRefresh() =>
      _navToStep().whenComplete(() => setState(() {}));

  Future<void> _navToStep() async {
    // Checking if our step is null and if we should flag its index as inactive
    final step = currentStep;
    if (step == null) return;

    // Navigating to the OnboardingStep Widget's route.
    try {
      final currentRouteName = widget.controller.observer.currentRouteName;

      // We want to navigate only if we are not already on the desired route.
      // If we are on the first step, we always want to navigate to this screen's step.
      if (currentRouteName != step.routeName || _currentIndex == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.controller
              .getNavigatorState()
              ?.pushReplacementNamed(step.routeName, arguments: step.arguments);
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

    // Waiting for the State of the screen
    final State<StatefulWidget>? state =
        widget.controller.getCurrentScreenKey()?.currentState;
    if (state == null) return;

    if (step.prepareNav != null) await step.prepareNav!(null, state);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (currentStep != null)
        OnboardingDialog(
            targetContext: context,
            complete: _complete,
            onboardingStep: currentStep,
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
