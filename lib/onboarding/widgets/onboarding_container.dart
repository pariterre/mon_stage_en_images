import 'package:flutter/widgets.dart';

class OnboardingContainer extends StatelessWidget {
  final Widget child;
  final void Function(BuildContext) onReady;

  const OnboardingContainer({
    super.key,
    required this.child,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        onReady(context);
      }
    });

    return child;
  }
}
