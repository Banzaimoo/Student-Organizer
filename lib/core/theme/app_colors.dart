import 'package:flutter/material.dart';

/// Semantic colors Material's ColorScheme does not provide
/// (warning for schedule clashes, success for finished tasks).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
  });

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  static const light = AppColors(
    warning: Color(0xFF7A5900),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFE08F),
    onWarningContainer: Color(0xFF261A00),
    success: Color(0xFF2E6B30),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFB1F1A9),
    onSuccessContainer: Color(0xFF002204),
  );

  static const dark = AppColors(
    warning: Color(0xFFF2C14B),
    onWarning: Color(0xFF402D00),
    warningContainer: Color(0xFF5C4300),
    onWarningContainer: Color(0xFFFFE08F),
    success: Color(0xFF96D58F),
    onSuccess: Color(0xFF00390A),
    successContainer: Color(0xFF14521B),
    onSuccessContainer: Color(0xFFB1F1A9),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
  }) =>
      AppColors(
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        warningContainer: warningContainer ?? this.warningContainer,
        onWarningContainer: onWarningContainer ?? this.onWarningContainer,
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
    );
  }
}
