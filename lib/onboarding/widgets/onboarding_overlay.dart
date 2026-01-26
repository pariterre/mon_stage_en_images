import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/onboarding/widgets/onboarding_dialog.dart';

class OnboardingController {
  final List<OnboardingStep> steps;

  OnboardingController({
    required this.steps,
    required this.onOnboardStarted,
    required this.onOnboardingCompleted,
  });

  final Future<void> Function() onOnboardStarted;
  final Future<void> Function() onOnboardingCompleted;

  _OnboardingOverlayState? _overlayState;
  bool _isOnboarding = false;
  bool get isOnboarding => _isOnboarding;
  Future<void> requestOnboarding() async {
    _isOnboarding = true;
    _currentIndex = 0;
    await onOnboardStarted();
    await _overlayState?._navToStepAndRefresh();
  }

  int _currentIndex = 0;

  Future<void> _showNextStep() async {
    if (_currentIndex >= steps.length) return;

    _currentIndex++;
    await _overlayState!._navToStepAndRefresh();

    if (_currentIndex >= steps.length) _terminateOnboarding();
  }

  Future<void> _showPreviousStep() async {
    if (_currentIndex < 1) return;

    _currentIndex--;
    await _overlayState!._navToStepAndRefresh();
  }

  Future<void> _terminateOnboarding() async {
    _isOnboarding = false;
    _currentIndex = steps.length;
    await onOnboardingCompleted();
    await _overlayState!._navToStepAndRefresh();
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
  OnboardingStep? get _currentStep {
    if (!widget.controller._isOnboarding ||
        widget.controller._currentIndex >= widget.controller.steps.length) {
      return null;
    }
    return widget.controller.steps[widget.controller._currentIndex];
  }

  @override
  void initState() {
    widget.controller._overlayState = this;

    super.initState();
  }

  /// Navigates to screen based on the index provided if needed. Then, it prepares the screen to actually
  /// display the targeted widget

  Future<void> _navToStepAndRefresh() async {
    // Checking if our step is null and if we should flag its index as inactive
    final step = _currentStep;
    if (step == null) {
      setState(() {});
      return;
    }

    if (step.navigationCallback != null) step.navigationCallback!(context);
    await _waitForWidgetsToBuild(step);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Waits for the targeted widgets to be built before displaying the onboarding dialog
  Future<void> _waitForWidgetsToBuild(OnboardingStep step) async {
    if (step.targetWidgetContext == null) return;

    var context = step.targetWidgetContext!();
    while (!(context?.mounted ?? false)) {
      // Wait for one frame
      await Future.delayed(const Duration(milliseconds: 50));
      context = step.targetWidgetContext!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_currentStep != null)
        OnboardingDialog(
          onboardingStep: _currentStep!,
          onForward: () async => await widget.controller._showNextStep(),
          onBackward: widget.controller._currentIndex > 0
              ? () async => await widget.controller._showPreviousStep()
              : null,
          onboardingTerminationRequest: () async => await widget.controller
              ._terminateOnboarding(), // Allowing the user to quit the onboarding
          isLastStep: widget.controller._currentIndex ==
              widget.controller.steps.length - 1,
        ),
    ]);
  }
}
