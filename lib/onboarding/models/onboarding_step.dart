import 'package:flutter/material.dart';

/// Represents a step in the onboarding sequence.
class OnboardingStep {
  const OnboardingStep(
      {required this.title,
      required this.routeName,
      required this.message,
      this.arguments,
      this.isLast = false,
      this.prepareNav});

  /// The registered route inside which the targeted widget will be highlighted during onboarding
  final String routeName;

  /// Arguments required by the widget to be given to the route
  final Object? arguments;

  /// A string shared by instance of this class and the OnboardingTarget widget to find the targeted widget across the tree.
  /// Link between these objects is permitted by the OnboardingKeysService. targetId Strings are available in the OnboardingStepList.
  final String title;

  final bool isLast;

  /// The message to be displayed inside the onboarding dialog for this step
  final String message;

  /// A function to be called by the Onboarding service after the navigation to route is done, if additional
  /// actions are needed in order to allow the targeted widget to be mounted inside the tree. Typically, opening
  /// a drawer or interacting with a controller to jump to a page inside a TabView or PageView.
  final Future<void> Function(
      BuildContext? context, State<StatefulWidget>? state)? prepareNav;

  void resetScaffoldElements(
      BuildContext context, State<StatefulWidget> state) {
    if (!state.mounted) return;

    final scaffoldState = Scaffold.of(context);
    if (scaffoldState.isDrawerOpen == true) scaffoldState.closeDrawer();
  }
}
