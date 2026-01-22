import 'package:flutter/material.dart';

class Helpers {
  /// Get the RenderBox from the widgetKey getter, which is linked to the targeted Widget in the tree
  /// Uses the Render Box to draw a Rect with an absolute position on the screen and some padding around.
  static Rect? rectFromWidgetKey(
      BuildContext context, BuildContext? targetContext) {
    final widgetObject = targetContext?.findRenderObject() as RenderBox?;
    if (targetContext?.mounted != true || widgetObject?.hasSize != true) {
      return null;
    }

    final offset = widgetObject!.localToGlobal(
        Offset(0, 0 - MediaQuery.of(targetContext!).padding.top));
    final rect = EdgeInsets.all(12).inflateRect(offset & widgetObject.size);
    return context.mounted ? rect : null;
  }
}
