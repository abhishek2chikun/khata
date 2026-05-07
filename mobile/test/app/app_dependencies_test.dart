import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_dependencies.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';

void main() {
  test('API dependencies preserve api mode label', () async {
    final dependencies = await AppDependencies.create(mode: DataMode.api);
    expect(dependencies.mode, DataMode.api);
    await dependencies.dispose();
  });
}
