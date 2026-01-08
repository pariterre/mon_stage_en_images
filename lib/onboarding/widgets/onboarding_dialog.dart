import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mon_stage_en_images/main.dart';
import 'package:mon_stage_en_images/onboarding/models/onboarding_step.dart';

final _logger = Logger('OnboardingDialogWithHighlight');

/// Main widget for displaying an onboarding dialog with a background clipped
/// to highlight the targeted Widget. Performs some stabilty checks,
/// allowing any standard duration animation to complete
/// before drawing the highlighted area
class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({
    super.key,
    required this.targetContext,
    this.manualHoleRect = Rect.zero,
    this.onboardingStep,
    this.complete,
    required this.onForward,
    this.onBackward,
  });

  /// Optional holeRect for overriding the clip provided by the globalKey (onboardingStep property)
  final Rect? manualHoleRect;

  final OnboardingStep? onboardingStep;
  final BuildContext targetContext;

  final void Function() onForward;
  final void Function()? onBackward;
  final void Function()? complete;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog>
    with WidgetsBindingObserver {
  /// Rect to be displayed on the overlay
  final ValueNotifier<Rect?> _rectNotifier = ValueNotifier(null);

  Timer? _rectDrawTimer;

  /// Tracks tentatives to draw a rect
  int _drawAttempts = 0;

  /// Last different rect drawn
  Rect? _lastRect;

  /// Maximum attempts allowed to draw a rect for the current onboarding step
  final int _maxAttempts = 30;

  /// Number of consecutive identical rect drawn to be confident that any navigation animation is completed
  /// and that our target widget won't move on the view anymore
  final int _consecutiveIdenticalRectRequired = 3;

  /// Delay after which the rect drawing process will start again
  final Duration _retryDelay = Duration(milliseconds: 40);

  late int _consecutiveEqualRects;

  late bool _navEnabled;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _navEnabled = true;
    _consecutiveEqualRects = 0;
    _resetAndDrawNewRect();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rectDrawTimer?.cancel();
    _rectNotifier.dispose();
    super.dispose();
  }

  // Refreshes the rect when the onboardingStep provided to this widget changes.
  @override
  void didUpdateWidget(covariant OnboardingDialog oldWidget) {
    if (oldWidget.key != widget.key) {
      _resetAndDrawNewRect();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeMetrics() {
    _logger.finest('didChangeMetrics called in OnBoardingDialogWithHighlight');
    setState(() {
      _resetAndDrawNewRect();
    });
    super.didChangeMetrics();
  }

  /// Sets the navigation buttons' state
  void _setNavTo(bool value) {
    if (value != _navEnabled) {
      setState(() {
        _navEnabled = value;
      });
    }
  }

  /// Resets every timer and attempts counter used to limit our calls to _rectFromWidgetKeyLabel
  /// and then starts another sequence of rect drawing
  void _resetAndDrawNewRect() {
    _rectDrawTimer?.cancel();
    _rectDrawTimer = null;
    _drawAttempts = 0;
    _rectNotifier.value = null;
    _setNavTo(false);
    _tryDrawRect();
  }

  /// Tries to draw a rect from the widget.targetId provided and then tests its stability across several frames.
  /// This check prevents an early display of the rect during any navigation animation.
  void _tryDrawRect() {
    if (!mounted) {
      _setNavTo(true);
      return;
    }

    // Do we exceed the permitted max attempts ?
    if (_drawAttempts >= _maxAttempts) {
      _logger.finest('_tryDrawRect : max Attempts reached, returning');
      _setNavTo(true);
      return;
    }

    _drawAttempts++;

    // We will try to draw our rect
    final Rect? rect = _rectFromWidgetKeyLabel(widget.targetContext);

    if (rect == null) {
      _logger.finest(
          '_tryDrawRect : rect is null after _rectFromWidgetKeyLabel,retyring and returning');
      _waitAndRetry();
      return;
    }

    // // The rect has changed since the last attempt, we don't want to display it as it is not yet stable.
    // if (rect != _lastRect) {
    //   _logger.finest(
    //       '_tryDrawRect : rect $rect !=  _lastRect $_lastRect after _rectFromWidgetKeyLabel, retrying and returning');
    //   _lastRect = rect;
    //   _consecutiveEqualRects = 0;
    //   _waitAndRetry();
    //   return;
    // }

    // // Rect hasn't changed since the last attempt, it is now a good candidate to be shown, but we need to check
    // // if its value will remain stable across several frames.
    // if (rect == _lastRect) {
    //   _consecutiveEqualRects++;
    //   _logger.finest(
    //       '_tryDrawRect : rect and _lastRect identical ! Increasing _consecutiveEqualRects to $_consecutiveEqualRects ');

    //   // Now we are confident that the rect won't change anymore,
    //   // we can display it and trigger a rebuild through ValueNotifierListenable in build.
    //   if (_consecutiveEqualRects >= _consecutiveIdenticalRectRequired) {
    //     _logger.finest(
    //         '_tryDrawRect : _consecutiveEqualRects is $_consecutiveEqualRects, exceeding _consecutiveIdenticalRectRequired. Rect is stable, changing _rectNotifier.value to $rect');
    //     _rectNotifier.value = rect;
    //     _setNavTo(true);
    //     return;
    //   }
    //   // We need more attempts to be sure that the rect is stable
    //   _logger.finest(
    //       '_tryDrawRect : _consecutiveEqualRects is $_consecutiveEqualRects, rerunning _tryDrawRect until it reaches _consecutiveIdenticalRectRequired');
    //   _waitAndRetry();
    //   return;
    // }
  }

  /// An helper to rerun _tryDrawRect after some delay
  void _waitAndRetry() {
    _rectDrawTimer = Timer(_retryDelay, _tryDrawRect);
  }

  /// Get the RenderBox from the widgetKey getter, which is linked to the targeted Widget in the tree
  /// Uses the Render Box to draw a Rect with an absolute position on the screen and some padding around.
  Rect? _rectFromWidgetKeyLabel(BuildContext targetContext) {
    Rect? rect;

    _logger.finest('_rectFromWidgetKeyLabel : context is $targetContext');

    if (!targetContext.mounted) {
      _logger.severe(
          '_rectFromWidgetKeyLabel : context is not mounted when trying to get widgetObject, returning');
      return null;
    }
    final widgetObject = targetContext.findRenderObject() as RenderBox?;
    if (widgetObject == null) {
      _logger.severe(
          '_rectFromWidgetKeyLabel : widgetObject is null after trying to find the RenderBox');
      return null;
    }

    if (!targetContext.mounted) {
      _logger.severe(
          '_rectFromWidgetKeyLabel : targetContext is not mounted after defining insets, returning');
      return null;
    }

    final vertOffset = MediaQuery.of(targetContext).padding.top;

    final offset = widgetObject.localToGlobal(Offset(0, 0 - vertOffset));
    if (!widgetObject.hasSize) {
      _logger.severe(
          '_rectFromWidgetKeyLabel : widgetObject has no size after getting its localToGlobal, returning null');
      return null;
    }
    final size = widgetObject.size;
    final insets = EdgeInsets.all(12);

    rect = insets.inflateRect(offset & size);

    if (!mounted) {
      _logger.severe(
          '_rectFromWidgetKeyLabel : context isn\'t mounted after getting widgetObject\'s renderbox, returning null');
      return null;
    }
    _logger.finest('_rectFromWidgetKeyLabel : rect is $rect');
    return rect;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ignoring click events inside the scrim
        AbsorbPointer(
          absorbing: true,
          child: Container(),
        ),
        // Clipping the area of the screen where the targeted widget is visible
        ValueListenableBuilder(
          valueListenable: _rectNotifier,
          builder: (context, Rect? rect, child) {
            return ClipPath(
                clipper: rect != null ? _HoleClipper(holeRect: rect) : null,
                child: Container(
                  decoration:
                      BoxDecoration(color: Colors.black.withValues(alpha: 0.6)),
                  height: double.infinity,
                  width: double.infinity,
                ));
          },
        ),

        // Shortcut to complete the onboarding
        if (showDebugOverlay)
          Center(
            child: FloatingActionButton(
              onPressed: widget.complete,
              child: Icon(Icons.check),
            ),
          ),
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
                  Text(widget.onboardingStep!.message,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Theme.of(context).cardColor)),
                  SizedBox(
                    height: 4,
                  ),
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
                              onPressed: _navEnabled
                                  ? () {
                                      widget.onBackward!();
                                      _setNavTo(false);
                                    }
                                  : null,
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
                          onPressed: _navEnabled
                              ? () async {
                                  widget.onForward();
                                  _setNavTo(false);
                                }
                              : null,
                          label: Text('Suivant',
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
