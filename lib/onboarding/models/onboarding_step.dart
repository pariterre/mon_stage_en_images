import 'package:flutter/material.dart';

/// Represents a step in the onboarding sequence.
class OnboardingStep {
  const OnboardingStep({
    required this.message,
    this.targetWidgetContext,
    required this.navigationCallback,
  });

  /// The message to be displayed inside the onboarding dialog for this step
  final String message;

  /// The widget context to be highlighted during this step. If none is provided
  /// the onboarding dialog will be shown without any highlight.
  final BuildContext? Function()? targetWidgetContext;

  /// A callback by the Onboarding service to perform the required navigation,
  /// e.g. navigating to a new page, opening a drawer, etc.
  final void Function(BuildContext onboardingContext)? navigationCallback;
}
