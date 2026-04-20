import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// App-wide platform & form-factor helpers.
///
/// Use these instead of scattering [Platform] / [defaultTargetPlatform] checks.
abstract final class AppPlatform {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Material "medium" window class and above (small tablet / phone landscape).
  /// Shortest side ≥ 600 dp.
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  /// Material "expanded" window class (large tablet / landscape tablet).
  /// Width ≥ 840 dp — triggers two-pane layouts.
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 840;
}
