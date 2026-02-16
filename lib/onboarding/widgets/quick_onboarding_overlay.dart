import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/onboarding/onboarding.dart';
import 'package:mon_stage_en_images/onboarding/widgets/onboarding_dialog.dart';

/// Main widget for displaying an onboarding dialog with a background clipped
/// to highlight the targeted Widget. Performs some stabilty checks,
/// allowing any standard duration animation to complete
/// before drawing the highlighted area

class QuickOnboardingOverlay extends StatefulWidget {
  const QuickOnboardingOverlay({
    super.key,
    this.message,
    this.widgetContext,
    this.onTap,
    required this.child,
  });

  final String? message;
  final BuildContext? widgetContext;
  final Function()? onTap;
  final Widget child;

  @override
  State<QuickOnboardingOverlay> createState() => _QuickOnboardingOverlayState();
}

class _QuickOnboardingOverlayState extends State<QuickOnboardingOverlay>
    with WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    setState(() {});
    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.widgetContext == null) return widget.child;

    MediaQuery.of(context); // Force rebuild on MediaQuery changes

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          widget.child,
          OnboardingDialog(
            onboardingStep: OnboardingStep(
                message: widget.message,
                targetWidgetContext: () => widget.widgetContext,
                navigationCallback: (_) {
                  if (widget.onTap != null) widget.onTap!();
                }),
            onForward: () {
              if (widget.onTap != null) widget.onTap!();
            },
            onBackward: null,
            onboardingTerminationRequest: () {
              if (widget.onTap != null) widget.onTap!();
            },
            isLastStep: true,
          ),
        ],
      ),
    );
  }
}
