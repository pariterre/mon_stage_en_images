import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/onboarding/helpers/helpers.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';
import 'package:mon_stage_en_images/onboarding/widgets/hole_clipper.dart';

/// Main widget for displaying an onboarding dialog with a background clipped
/// to highlight the targeted Widget. Performs some stabilty checks,
/// allowing any standard duration animation to complete
/// before drawing the highlighted area
class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({
    super.key,
    required this.onboardingStep,
    required this.onForward,
    required this.onBackward,
    required this.onboardingTerminationRequest,
    required this.isLastStep,
  });

  final OnboardingStep onboardingStep;

  final void Function() onForward;
  final void Function()? onBackward;
  final void Function() onboardingTerminationRequest;

  final bool isLastStep;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog>
    with WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    setState(() {});
    super.didChangeMetrics();
  }

  Rect? _previousRectToClip;
  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context); // Force rebuild on MediaQuery changes

    final rectToClip = widget.onboardingStep.targetWidgetContext == null
        ? null
        : Helpers.rectFromWidgetKey(
            context, widget.onboardingStep.targetWidgetContext!());

    final isReady =
        widget.onboardingStep.targetWidgetContext == null || rectToClip != null;

    if (isReady && rectToClip != null) {
      // Check for moving elements / animations by repeating the setState call
      if (_previousRectToClip != rectToClip) {
        _previousRectToClip = rectToClip;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }

    return Stack(
      children: [
        // Ignoring click events inside the scrim
        AbsorbPointer(absorbing: true, child: Container()),

        // Clipping the area of the screen where the targeted widget is visible
        if (isReady)
          ClipPath(
              clipper:
                  rectToClip == null ? null : HoleClipper(holeRect: rectToClip),
              child: Container(
                decoration:
                    BoxDecoration(color: Colors.black.withValues(alpha: 0.6)),
                height: double.infinity,
                width: double.infinity,
              )),

        // Displays the onboardingStep
        Dialog(
          backgroundColor: Theme.of(context).colorScheme.scrim.withAlpha(225),
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    width: 4, color: Theme.of(context).primaryColor)),
            child: Column(
              spacing: 12,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0, top: 12.0),
                        child: Text(widget.onboardingStep.message,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(color: Theme.of(context).cardColor)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                          onPressed: () =>
                              widget.onboardingTerminationRequest(),
                          child: Text('X',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right)),
                    )
                  ],
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 12,
                    runAlignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      if (widget.onBackward != null)
                        OutlinedButton.icon(
                            onPressed: () => widget.onBackward!(),
                            iconAlignment: IconAlignment.start,
                            icon: Icon(Icons.keyboard_arrow_left_sharp),
                            label: Text(
                              'Précédent',
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .fontSize),
                            )),
                      FilledButton.icon(
                        onPressed: () => widget.onForward(),
                        label: Text(widget.isLastStep ? 'Terminer' : 'Suivant',
                            style: TextStyle(
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .fontSize)),
                        icon: Icon(Icons.keyboard_arrow_right_sharp),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.0),
              ],
            ),
          ),
        )
      ],
    );
  }
}
