import 'package:flutter_test/flutter_test.dart';
import 'package:verto/core/update_service.dart';

void main() {
  test('compareVersions orders versions numerically', () {
    expect(compareVersions('1.0.1', '1.0.0'), 1);
    expect(compareVersions('1.0.0', '1.0.0+5'), 0);
    expect(compareVersions('v1.10.0', '1.9.9'), 1);
    expect(compareVersions('1.0', '1.0.1'), -1);
    expect(compareVersions('2.0.0-beta', '1.9.9'), 1);
  });
}
