import 'package:flutter/material.dart';

/// Brand palette used to construct Material 3 [ColorScheme]s.
class AppColors {
  AppColors._();

  static const Color brandTeal = Color(0xFF0F6B73);
  static const Color brandTealDark = Color(0xFF04363B);
  static const Color brandTealLight = Color(0xFF8AD4DB);
  static const Color brandGold = Color(0xFF9A7209);

  static const Color success = Color(0xFF027A48);
  static const Color successContainer = Color(0xFFD1FADF);
  static const Color warning = Color(0xFFB54708);
  static const Color warningContainer = Color(0xFFFEF0C7);
  static const Color info = Color(0xFF175CD3);
  static const Color infoContainer = Color(0xFFD1E0FF);
  static const Color overdue = Color(0xFFB42318);
  static const Color overdueContainer = Color(0xFFFEE4E2);

  static ColorScheme get lightScheme {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: brandTeal,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFC5E8EC),
      onPrimaryContainer: brandTealDark,
      secondary: brandGold,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF8E5B0),
      onSecondaryContainer: Color(0xFF3D2C00),
      tertiary: Color(0xFF3B6D4A),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFC9EBD3),
      onTertiaryContainer: Color(0xFF0B2A16),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFF6FAFA),
      onSurface: Color(0xFF151C1D),
      onSurfaceVariant: Color(0xFF3F494A),
      outline: Color(0xFF6F7A7B),
      outlineVariant: Color(0xFFBFC8C9),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2A3233),
      onInverseSurface: Color(0xFFECF2F2),
      inversePrimary: brandTealLight,
      surfaceTint: brandTeal,
    );
  }

  static ColorScheme get darkScheme {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: brandTealLight,
      onPrimary: brandTealDark,
      primaryContainer: Color(0xFF0F6B73),
      onPrimaryContainer: Color(0xFFC5E8EC),
      secondary: Color(0xFFE3C46A),
      onSecondary: Color(0xFF3D2C00),
      secondaryContainer: Color(0xFF5C4400),
      onSecondaryContainer: Color(0xFFF8E5B0),
      tertiary: Color(0xFFA8D0B4),
      onTertiary: Color(0xFF0B2A16),
      tertiaryContainer: Color(0xFF235336),
      onTertiaryContainer: Color(0xFFC9EBD3),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0E1415),
      onSurface: Color(0xFFDEE4E4),
      onSurfaceVariant: Color(0xFFBFC8C9),
      outline: Color(0xFF899394),
      outlineVariant: Color(0xFF3F494A),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFDEE4E4),
      onInverseSurface: Color(0xFF2A3233),
      inversePrimary: brandTeal,
      surfaceTint: brandTealLight,
    );
  }
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.overdue,
    required this.onOverdue,
    required this.overdueContainer,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color overdue;
  final Color onOverdue;
  final Color overdueContainer;

  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>()!;
  }

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColors.success,
    onSuccess: Color(0xFFFFFFFF),
    successContainer: AppColors.successContainer,
    warning: AppColors.warning,
    onWarning: Color(0xFFFFFFFF),
    warningContainer: AppColors.warningContainer,
    info: AppColors.info,
    onInfo: Color(0xFFFFFFFF),
    infoContainer: AppColors.infoContainer,
    overdue: AppColors.overdue,
    onOverdue: Color(0xFFFFFFFF),
    overdueContainer: AppColors.overdueContainer,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF6CE9A6),
    onSuccess: Color(0xFF052E1C),
    successContainer: Color(0xFF054F31),
    warning: Color(0xFFFEC84B),
    onWarning: Color(0xFF3D2A00),
    warningContainer: Color(0xFF7A4D00),
    info: Color(0xFF84CAFF),
    onInfo: Color(0xFF002C5C),
    infoContainer: Color(0xFF0B4A9A),
    overdue: Color(0xFFFEA3A0),
    onOverdue: Color(0xFF5C1510),
    overdueContainer: Color(0xFF7A271A),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? overdue,
    Color? onOverdue,
    Color? overdueContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      overdue: overdue ?? this.overdue,
      onOverdue: onOverdue ?? this.onOverdue,
      overdueContainer: overdueContainer ?? this.overdueContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      onOverdue: Color.lerp(onOverdue, other.onOverdue, t)!,
      overdueContainer: Color.lerp(overdueContainer, other.overdueContainer, t)!,
    );
  }
}
