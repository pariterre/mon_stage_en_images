import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/onboarding/helpers/helpers.dart';
import 'package:mon_stage_en_images/onboarding/widgets/hole_clipper.dart';

/// Main widget for displaying an onboarding dialog with a background clipped
/// to highlight the targeted Widget. Performs some stabilty checks,
/// allowing any standard duration animation to complete
/// before drawing the highlighted area

// TODO Add dialog if String != null

class QuickOnboardingOverlay extends StatefulWidget {
  const QuickOnboardingOverlay({
    super.key,
    this.widgetContext,
    this.onTap,
    required this.child,
  });

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

  Rect? _previousRectToClip;

  @override
  Widget build(BuildContext context) {
    if (widget.widgetContext == null) return widget.child;

    MediaQuery.of(context); // Force rebuild on MediaQuery changes

    final rectToClip = Helpers.rectFromWidgetKey(context, widget.widgetContext);

    final isReady = rectToClip != null;
    if (isReady) {
      // Check for moving elements / animations by repeating the setState call
      if (_previousRectToClip != rectToClip) {
        _previousRectToClip = rectToClip;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          widget.child,
          if (isReady)
            ClipPath(
                clipper: HoleClipper(holeRect: rectToClip),
                child: Container(
                  decoration:
                      BoxDecoration(color: Colors.black.withValues(alpha: 0.6)),
                  height: double.infinity,
                  width: double.infinity,
                )),
        ],
      ),
    );
  }
}
