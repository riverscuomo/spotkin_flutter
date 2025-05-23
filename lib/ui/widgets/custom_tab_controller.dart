import 'package:flutter/material.dart';

// Custom tab controller that prevents the user from swiping to the last tab
class CustomTabController extends TabController {
  CustomTabController(
      {required super.initialIndex,
      required super.length,
      required super.vsync});

  @override
  void animateTo(int value, {Curve curve = Curves.ease, Duration? duration}) {
    if (value != length - 1) {
      super.animateTo(value, curve: curve, duration: duration);
    }
  }
}
