import 'package:flutter/widgets.dart';

class OnboardingContainer extends StatefulWidget {
  const OnboardingContainer({
    super.key,
    required this.child,
    required this.onInitialize,
  });

  final Widget child;
  final void Function(BuildContext) onInitialize;

  @override
  State<OnboardingContainer> createState() => _OnboardingContainerState();
}

class _OnboardingContainerState extends State<OnboardingContainer> {
  @override
  void initState() {
    widget.onInitialize(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
