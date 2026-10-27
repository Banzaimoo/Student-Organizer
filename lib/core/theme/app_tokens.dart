import 'package:flutter/animation.dart';

/// Spacing scale (4/8 base). Use these instead of ad-hoc numbers.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Shape lock: inputs, cards and grouped lists use [md]; chips use [sm];
/// buttons keep the Material 3 full pill.
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
}

/// Motion only conveys state. Keep UI transitions under 250 ms.
class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;
}

/// Max content widths so forms and lists stay readable on wide screens.
class AppLayout {
  static const double formMaxWidth = 560;
  static const double listMaxWidth = 720;

  /// Card grids get more room so wide screens fit 3–4 columns.
  static const double gridMaxWidth = 1200;
}
