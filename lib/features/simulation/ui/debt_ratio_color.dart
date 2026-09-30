import 'dart:ui';

import '../../../core/theme/app_colors.dart';
import '../domain/rules.dart';

/// Green, orange strictly above 33%, red strictly above 35%, judged on the
/// displayed value (hundredths of a percent).
Color debtRatioColor(double ratio) {
  final shown = (ratio * 10000).round();
  if (shown > (Rules.debtRatioLimit * 10000).round()) return AppColors.danger;
  if (shown > (Rules.debtRatioWarning * 10000).round()) {
    return AppColors.warning;
  }
  return AppColors.success;
}
