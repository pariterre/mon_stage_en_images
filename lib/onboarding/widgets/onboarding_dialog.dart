import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';

/// Main widget for displaying an onboarding dialog with a background clipped
/// to highlight the targeted Widget. Performs some stabilty checks,
/// allowing any standard duration animation to complete
/// before drawing the highlighted area
class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({
    super.key,
    this.manualHoleRect = Rect.zero,
    required this.onboardingStep,
    required this.onForward,
    required this.onBackward,
    required this.isLastStep,
  });

  /// Optional holeRect for overriding the clip provided by the globalKey (onboardingStep property)
  final Rect? manualHoleRect;

  final OnboardingStep onboardingStep;

  final void Function() onForward;
  final void Function()? onBackward;

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

  /// Get the RenderBox from the widgetKey getter, which is linked to the targeted Widget in the tree
  /// Uses the Render Box to draw a Rect with an absolute position on the screen and some padding around.
  Rect? _rectFromWidgetKey(BuildContext? targetContext) {
    final widgetObject = targetContext?.findRenderObject() as RenderBox?;
    if (targetContext?.mounted != true || widgetObject?.hasSize != true) {
      return null;
    }

    final offset = widgetObject!.localToGlobal(
        Offset(0, 0 - MediaQuery.of(targetContext!).padding.top));
    final rect = EdgeInsets.all(12).inflateRect(offset & widgetObject.size);
    return mounted ? rect : null;
  }

  Rect? _previousRectToClip;

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context); // Force rebuild on MediaQuery changes

    final rectToClip = widget.onboardingStep.targetWidgetContext == null
        ? null
        : _rectFromWidgetKey(widget.onboardingStep.targetWidgetContext!());

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
              clipper: rectToClip == null
                  ? null
                  : _HoleClipper(holeRect: rectToClip),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                spacing: 12,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.onboardingStep.message,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Theme.of(context).cardColor)),
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
                          label: Text(
                              widget.isLastStep ? 'Terminer' : 'Suivant',
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .fontSize)),
                          icon: Icon(Icons.keyboard_arrow_right_sharp),
                          iconAlignment: IconAlignment.end,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

/// Takes the Rect drawn from the Render Box of the targeted onboarding Widget
/// and substracts it to another path filling the whole view. Meant to be provided
/// to the OnBoardingDialogClippedBackground widget as a background for the onboarding dialog.
class _HoleClipper extends CustomClipper<Path> {
  const _HoleClipper({required this.holeRect});

  /// Whether the clipped zone should have rounded corners or not
  final bool makeRRect = true;

  /// Radius for the rounded corners clipped zone
  final double radius = 12;

  /// Rect drawn from the RenderBox of the targeted onboarding Widget.
  final Rect holeRect;

  @override
  Path getClip(Size size) {
    Path path = Path();

    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final rrectFromHoleRect =
        RRect.fromRectAndRadius(holeRect, Radius.circular(radius));

    makeRRect ? path.addRRect(rrectFromHoleRect) : path.addRect(holeRect);
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant _HoleClipper oldClipper) {
    return true;
  }
}
