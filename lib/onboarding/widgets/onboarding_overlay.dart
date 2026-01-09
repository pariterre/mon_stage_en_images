import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/onboarding/controllers/onboarding_route_observer.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/onboarding/widgets/onboarding_dialog.dart';

class OnboardingController {
  final List<OnboardingStep> steps;

  OnboardingController({
    required this.steps,
    required this.onOnboardingCompleted,
  }) {
    _resetCurrentIndex();
  }

  final observer = OnboardingRouteObserver();

  final VoidCallback onOnboardingCompleted;

  _OnboardingOverlayState? _overlayState;
  void requestOnboarding() {
    if (_overlayState?._currentStep == null) {
      _resetCurrentIndex();
      _overlayState?._navToStepAndRefresh();
    }
  }

  int? _currentIndex;
  void _resetCurrentIndex() => _currentIndex = steps.isNotEmpty ? 0 : null;

  Future<void> _showNextStep() async {
    if (_currentIndex == null || _currentIndex! >= steps.length) {
      return;
    }

    _currentIndex = _currentIndex! + 1;
    await _overlayState!._navToStepAndRefresh();

    if (_currentIndex! == steps.length) {
      onOnboardingCompleted();
    }
  }

  Future<void> _showPreviousStep() async {
    if (_currentIndex == null || _currentIndex! < 1) {
      return;
    }

    _currentIndex = _currentIndex! - 1;
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
    this.showDebugOptions = false,
  });

  final Widget child;
  final OnboardingController controller;
  final bool showDebugOptions;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  OnboardingStep? get _currentStep {
    if (widget.controller._currentIndex == null ||
        widget.controller._currentIndex! >= widget.controller.steps.length) {
      return null;
    }
    return widget.controller.steps[widget.controller._currentIndex!];
  }

  @override
  void initState() {
    widget.controller._overlayState = this;

    super.initState();
  }

  bool _isProcessingNav = false;

  /// Navigates to screen based on the index provided if needed. Then, it prepares the screen to actually
  /// display the targeted widget

  Future<void> _navToStepAndRefresh() async {
    _isProcessingNav = true;

    // Checking if our step is null and if we should flag its index as inactive
    final step = _currentStep;
    if (step == null) {
      setState(() {
        _isProcessingNav = false;
      });
      return;
    }

    if (step.navigationCallback != null) {
      await step.navigationCallback!(context);
    }
    await _waitForWidgetsToBuild(step);

    setState(() {
      _isProcessingNav = false;
    });
  }

  // Waits for the targeted widgets to be built before displaying the onboarding dialog
  Future<void> _waitForWidgetsToBuild(OnboardingStep step) async {
    if (step.targetWidgetContext == null) return;

    var context = step.targetWidgetContext!();
    if (!(context?.mounted ?? false)) {
      // Wait for one frame
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_currentStep != null && !_isProcessingNav)
        OnboardingDialog(
            onboardingStep: _currentStep!,
            onForward: () async => await widget.controller._showNextStep(),
            onBackward: (widget.controller._currentIndex ?? -1) > 0
                ? () async => await widget.controller._showPreviousStep()
                : null),
      // Shortcut to complete the onboarding
      if (widget.showDebugOptions)
        Center(
          child: FloatingActionButton(
            onPressed: widget.controller.onOnboardingCompleted,
            child: Icon(Icons.check),
          ),
        ),
    ]);
  }
}
