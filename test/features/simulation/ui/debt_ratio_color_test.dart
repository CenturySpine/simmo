import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/core/theme/app_colors.dart';
import 'package:simmo/features/simulation/ui/debt_ratio_color.dart';

void main() {
  test('green up to 33%, orange above, red strictly above 35%', () {
    expect(debtRatioColor(0.33), AppColors.success);
    expect(debtRatioColor(0.3301), AppColors.warning);
    expect(debtRatioColor(0.35), AppColors.warning);
    expect(debtRatioColor(0.3500000001), AppColors.warning);
    expect(debtRatioColor(0.3501), AppColors.danger);
  });
}
