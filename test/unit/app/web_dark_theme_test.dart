import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web dark material theme uses neutral web background surfaces', () {
    final theme = AppTheme.materialThemeWebDark();
    final scheme = theme.colorScheme;

    expect(theme.scaffoldBackgroundColor, AppColors.webDarkBackground);
    expect(scheme.surface, AppColors.webDarkBackground);
    expect(scheme.surfaceContainerLowest, AppColors.webDarkBackground);
    expect(scheme.surfaceContainerLow, AppColors.webDarkBackground);
    expect(scheme.surfaceContainerHighest, AppColors.webDarkBackground);
    expect(theme.inputDecorationTheme.fillColor, AppColors.webDarkBackground);
  });

  test('regular dark material theme keeps the mobile warm charcoal', () {
    final theme = AppTheme.materialThemeDark();

    expect(theme.scaffoldBackgroundColor, AppColors.brandCharcoal);
    expect(theme.scaffoldBackgroundColor, isNot(AppColors.webDarkBackground));
  });
}
