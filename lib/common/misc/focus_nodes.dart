import 'package:flutter/material.dart';

class FocusNodes {
  final _list = <String, FocusNode>{};
  final _order = <String>[];
  FocusNodes();

  void add(String name) {
    _list[name] = FocusNode();
    _order.add(name);
  }

  FocusNode operator [](String name) => _list[name]!;

  void dispose() {
    for (final node in _list.values) {
      node.dispose();
    }
  }

  int get _currentIndex {
    final focusedNodeIndex = _order.indexWhere((name) => _list[name]!.hasFocus);
    return focusedNodeIndex == -1 ? 0 : focusedNodeIndex;
  }

  void next() {
    final nextIndex = (_currentIndex + 1) % _order.length;
    _list[_order[nextIndex]]!.requestFocus();
  }
}
